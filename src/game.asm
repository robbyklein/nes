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
  lda #$00
  sta player_direction
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
    lda colors2, X
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
    lda colors, X
    sta PPUDATA
    inx
    cpx #$10
    bne :-


  ;;;;;;;;;;;;;;;;;;;;;;;
  ; Load Sprites
  ;;;;;;;;;;;;;;;;;;;;;;;
;   ldx #$00
; load_spirtes:
;   lda sprites, x
;   sta $0200, x
;   inx
;   cpx #$04
;   bne load_spirtes


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

  ; Move player
  lda player_y
  sta $0200 ; Y-coord of first sprite
  lda #$06
  sta $0201 ; tile number of first sprite
  lda #$00
  sta $0202 ; attributes of first sprite
  lda player_x
  sta $0203 ; X-coord of first sprite
  inc player_x

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
;; Externals
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

colors:
  .incbin "palettes.pal"

colors2:
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