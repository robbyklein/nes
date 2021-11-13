.include "constants.inc"

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

.segment "ZEROPAGE"
  player_x: .res 1
  player_y: .res 1
  player_direction: .res 1
  background: .res 2
  frames_passed: .res 1

.segment "STARTUP"
Reset:
  SEI
  CLD
  LDX #$00
  STX PPUCTRL
  STX PPUMASK
  
  ; initialize zero-page values
  LDA #$80
  STA player_x
  LDA #$cf
  STA player_y
  LDA #$00
  STA player_direction

:
  BIT $2002
  BPL :-


  ; Load sprite palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$10
  STX PPUADDR
  
  LDX #$00
LoadPalettes2:
    LDA colors2, X
    STA PPUDATA
    INX
    CPX #$10
    BNE LoadPalettes2


  ; Load background palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
  
  LDX #$00
LoadPalettes:
    LDA colors, X
    STA PPUDATA
    INX
    CPX #$10
    BNE LoadPalettes


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


  ;;;;;;;;;;;;;;;;;;;;;;;
  ; Load Background
  ;;;;;;;;;;;;;;;;;;;;;;;
  ldx #$20
  ldy #$00 ; position

  lda #<background_data
  sta background
  lda #>background_data
  sta background+1

; Background
page:
  tiles:
    LDA PPUSTATUS
    STX PPUADDR
    STY PPUADDR
    lda (background),y
    STa PPUDATA
    iny
    bne tiles

  inc background+1
  inx
  cpx #$24
  bne page
  
vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10000000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK


Loop:
    lda frames_passed

    :
      cmp frames_passed
      beq :-

      LDA player_y
      STA $0200 ; Y-coord of first sprite
      LDA #$06
      STA $0201 ; tile number of first sprite
      LDA #$00
      STA $0202 ; attributes of first sprite
      LDA player_x
      STA $0203 ; X-coord of first sprite

      inc player_x



    JMP Loop


NMI:
	  LDA #$00
	  STA OAMADDR
	  LDA #$02
	  STA OAMDMA
	  LDA #$00
	  STA $2005
    lda #$00
	  STA $2005
    ;inc $01
    inc frames_passed

	  RTI

colors:
  .incbin "palettes.pal"

colors2:
  .incbin "sprite-palettes.pal"

sprites:
  .byte $cf, $06, $00, $80
background_data:
  .incbin "bg.nam"

.segment "VECTORS"
    .word NMI
    .word Reset
    ; 
.segment "CHARS"
    .incbin "tiles.chr"