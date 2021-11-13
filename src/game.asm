;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Includes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.include "constants.inc"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Rom Header
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "HEADER"
  .byte "NES"
  .byte $1a
  .byte $02
  .byte $01 
  .byte %00000001
  .byte $00
  .byte $00
  .byte $00
  .byte $00
  .byte $00, $00, $00, $00, $00


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "ZEROPAGE"
  player_x: .res 1
  player_y: .res 1
  player_direction: .res 1
  background: .res 2
  frames_passed: .res 1
  scroll_x: .res 1
  scroll_y: .res 1
  falling: .res 1

.segment "STARTUP"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Reset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset:
  sei
  cld
  ldx #$00
  stx PPUCTRL
  stx PPUMASK
  
  ; initialize zero-page values
  lda #$7f
  sta player_x
  lda #$cf
  sta player_y
  lda #$00
  sta player_direction
  lda #$00
  sta scroll_x
  sta scroll_y
  sta falling

; wait for vblank
:
  bit PPUSTATUS
  bpl :-


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Load palettes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; Sprites
  ldx PPUSTATUS
  ldx #$3f
  stx PPUADDR
  ldx #$10
  stx PPUADDR
  ldx #$00
:
    lda sprite_palettes, X
    sta PPUDATA
    inx
    cpx #$10
    bne :-

  ; Backgrounds
  ldx PPUSTATUS
  ldx #$3f
  stx PPUADDR
  ldx #$00
  stx PPUADDR
  ldx #$00
:
    lda background_palettes, X
    sta PPUDATA
    inx
    cpx #$10
    bne :-


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Load background
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ldx #$20 ; offset
  ldy #$00 ; position
  lda #<background_data
  sta background
  lda #>background_data
  sta background+1

:
  render_background_tiles:
    ; render each position
    lda PPUSTATUS
    stx PPUADDR
    sty PPUADDR
    lda (background),y
    sta PPUDATA
    iny
    bne render_background_tiles
  ; Go to next page
  inc background+1
  inx
  cpx #$24
  bne :-

; Wait for vblack 
:
  bit PPUSTATUS
  bpl :-

  ; turn on NMIs, sprites use first pattern table
  lda #%10000000  
  sta PPUCTRL

  ; turn on screen
  lda #%00011110  
  sta PPUMASK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main game loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loop:
  ;; Wait for next frame ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  lda frames_passed
:
  cmp frames_passed
  beq :-

  ;; Render player ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  lda player_y
  sta $0200 ; Y-coord of first sprite
  lda #$06
  sta $0201 ; tile number of first sprite
  lda #$00
  sta $0202 ; attributes of first sprite
  lda player_x
  sta $0203 ; X-coord of first sprite

  ;; Read contoller input ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  lda #$01
  sta PAD1   ; start poll
  lda #$00
  sta PAD1   ; end poll

check_a:
  lda PAD1 ; a

  ; check if on ground
  ldx player_y
  cpx #$cf

  ; if your not finish jump
  bne finish_jump  ; skip if jumping

  AND #%00000001 ; See if a is pressed
  beq skipped_controls ; skip if not press

  ; if it is start jump
  dec player_y
  dec player_y

finish_jump:
  ; if falling continue fall
  lda falling
  cmp #$01
  beq fall

  ; otherwise keep jumping
  lda player_y
  cmp #$a1
  beq fall
  dec player_y
  dec player_y
  jmp skipped_controls

fall:
  lda #$01
  sta falling
  inc player_y
  inc player_y
  lda player_y
  cmp #$cf
  beq stop_fall
  jmp skipped_controls

stop_fall:
  lda #$00
  sta falling

skipped_controls:
  lda PAD1 ; b
  lda PAD1 ; select
  lda PAD1 ; start
  lda PAD1 ; up
  lda PAD1 ; down

check_left:
  lda PAD1 ; left
  AND #%00000001 ; See if left is pressed
  beq check_right  ; skip if not
  lda player_x
  cmp #$0f ; see if at edge
  beq check_right ; skip if so
  dec player_x ; else move left
  dec player_x

check_right:
  lda PAD1 ; right
  AND #%00000001 ; See if right is pressed
  beq continue2  ; skip note
  lda player_x
  cmp #$e9
  beq continue2
  inc player_x ; else move right
  inc player_x

  ;; Move player ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; move_player:
;   lda player_direction

;   ; if set to 2 move right
;   cmp #$02
;   beq move_right

;   ; if set to 1 move left
;   cmp $01
;   beq move_left

;   ; else skip movement
;   jmp continue

; move_right:
;   inc player_x

;   ; change direction if at edge
;   lda player_x
;   cmp #$e9
;   beq change_direction_left
;   jmp skip_direction

;   change_direction_left:
;     lda #$00
;     sta player_direction

;   skip_direction:
;     jmp continue

; move_left:
;   dec player_x

;   ; change direction at edge
;   lda player_x
;   cmp #$0f
;   beq change_direction_right
;   jmp skip_direction2

;   change_direction_right:
;     lda #$01
;     sta player_direction


continue2:
  ; infinite loop
  JMP loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; NMI
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
nmi:
	  lda #$00
	  sta OAMADDR
	  lda #$02
	  sta OAMDMA
    
    ; Scrol;
	  lda scroll_x
	  sta $2005
    lda scroll_y
	  sta $2005
    inc frames_passed
	  rti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Sprite Data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
player_sprite:
  .byte player_x, $06, $00, $80

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Externals
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

background_palettes:
  .incbin "palettes.pal"

sprite_palettes:
  .incbin "sprite-palettes.pal"

background_data:
  .incbin "bg.nam"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "VECTORS"
    .word nmi
    .word reset


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Chars
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "CHARS"
    .incbin "tiles.chr"