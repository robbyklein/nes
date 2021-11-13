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
  lda #$80
  sta player_x
  lda #$cf
  sta player_y
  lda #$01
  sta player_direction
  lda #$00
  sta scroll_x
  sta scroll_y

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
  lda frames_passed
  
; each frame
:
  cmp frames_passed
  beq :-

  ; Render player
  lda player_y
  sta $0200 ; Y-coord of first sprite
  lda #$06
  sta $0201 ; tile number of first sprite
  lda #$00
  sta $0202 ; attributes of first sprite
  lda player_x
  sta $0203 ; X-coord of first sprite

  ; Move player

  lda player_direction
  cmp #$01
  beq move_right
  jmp move_left

move_right:
  inc player_x

  ; change direction if at edge
  lda player_x
  cmp #$e9
  beq change_direction_left
  jmp skip_direction

  change_direction_left:
    lda #$00
    sta player_direction

  skip_direction:
    jmp continue

move_left:
  dec player_x

  ; change direction at edge
  lda player_x
  cmp #$0f
  beq change_direction_right
  jmp skip_direction2

  change_direction_right:
    lda #$01
    sta player_direction

  skip_direction2:
    jmp continue

continue:
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