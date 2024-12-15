globals [
  ; Time
  seconds-per-tick

  ; Current british wave
  current-wave

  wave-trigger-1
  wave-trigger-2

  ; Soldier counts
  num-colonist-soldiers     ; Total number of Colonist soldiers
  num-british-soldiers      ; Total number of British soldiers
  num-british-form1         ; Number of British soldiers in a given formation
  num-british-form2
  brit-balance              ; Percentage to go in form 1

  ; Casualty counts
  colonist-casualties       ; Count of Colonist casualties
  british-casualties        ; Count of British casualties

  ; Soldier parameters
  british-ammunition         ; Amount of ammunition for British soldiers
  colonist-ammunition        ; Amount of ammunition for Colonist soliders
  colonist-firing-speed      ; Rate of fire for Colonists
  british-firing-speed       ; Rate of fire for British
  colonist-distance-to-shoot ; The range Colonist soldiers can fire at, is determined by slider in the interface

  ; Weapon parameters
  max-effective-musket-distance ; The max effective rate of muskets

  ; Battlefield parameters
  british-retreat-percentage         ; percentage gives what percent of troop loss before retreat is necessitated
  colonial-retreat-percentage
  british-retreat-form1                    ; 0 to move forward, 1 to move backward
  british-retreat-form2


  ; Battlefield dimensions
  battlefield-width        ; Width of the battlefield in feet
  battlefield-height       ; Height of the battlefield in feet
  total-patches            ; Total number of patches
  bottom-cutoff
  total-hill-feet       ; The total feet of the hill

  ; Positioning and movement
  distance-to-target                ; Current distance to the nearest target

  ; Terrain parameters
  terrain-speeds                    ;corresponding speeds for each terrain type(this is a list)
  terrain-types

  ; Formation parameters
  spacing
  column-count1
  column-count2
  row-count
  x1
  x2

  british-wave-retreat ; a bool on if the british are currently temporarily retreating (from a wave)
  colonist-retreat ; if the Colonists are retreating

  total-brit-80
  total-col-80
  runs-80
  total-brit-160
  total-col-160
  runs-160
  total-brit-240
  total-col-240
  runs-240

  avg-brit-80
  avg-brit-160
  avg-brit-240
  avg-col-80
  avg-col-160
  avg-col-240
]

; assign turtle breeds and parameters for each
breed [british brit]
british-own [movementSpeed firingSpeed ammunitionCount canShoot hitRate closestSoldier soldierDistance formNum formRows retreat ] ; lets keep parameter names consistent across the two classes for now
breed [colonists colonist]
colonists-own [movementSpeed firingSpeed ammunitionCount canShoot hitRate closestSoldier soldierDistance formNum formRows retreat ]
patches-own [terrain-type]


; initialization procedure
to setup
  clear-all
  ; Set seconds per tick
  set seconds-per-tick 5

  ; Set initial counts of soldiers and initialize their turtles
  set num-colonist-soldiers 1500
  set num-british-soldiers 2000

  set current-wave 1
  ;setting curr
  ; Initialize battlefield dimensions
  set battlefield-width 4800                 ; Battlefield width (feet)
  set battlefield-height 2100                ; Battlefield height (feet)
  set total-patches count patches            ; Number of patches is determined in settings.
  set wave-trigger-1 false
  set wave-trigger-2 false


  ; Initialize terrain parameters

  ; setup-terrain
  setup-terrain          ; Call to setup terrain first

  set total-hill-feet 0
  ask patches [
    ; ignore pcolor 53, 25, and 45
    if (pcolor = 54) or (pcolor = 55) or (pcolor = 56) or (pcolor = 57) or (pcolor = 58)  [
        set total-hill-feet (total-hill-feet + 15)
    ]
  ]

  ; Initialize casualty counts
  set colonist-casualties 0
  set british-casualties 0

  ;DEATH PLOT CODE INITIALIZATION

  set-current-plot "Colonist Casualties Over Time"
  set-plot-x-range 0 400
  set-plot-y-range 0 num-colonist-soldiers
  clear-plot

  set-current-plot "British Casualties Over Time"
  set-plot-x-range 0 400
  set-plot-y-range 0 num-british-soldiers
  clear-plot


  ; Initialize soldier parameters
  set colonist-ammunition 24              ; initializing Colonist ammo
  set british-ammunition 60               ; initializing British ammo
  ; Initialize weapon parameters
  set colonist-distance-to-shoot distance-to-shoot ; this comes from the slider value
  set max-effective-musket-distance 300 ; 100 * 3 = 300

  ; Initialize battlefield parameters
  set british-retreat-percentage .13
  set british-retreat-form1 0
  set british-retreat-form2 0

  ; Initialize firing speed parameters, numbers and logic based off our powerpoint
  set colonist-firing-speed seconds-per-tick / 15  ; Colonist soldiers can fire approximately 0.067 shots per tick
                                      ; 1 shot every 15 seconds and assuming each tick represents 1 second, firing speed
  set british-firing-speed  seconds-per-tick / 16  ; British soldiers can fire approximately 0.0625 shots per tick
                                       ; similar logic for British

  set british-wave-retreat false

  ; Set initial British formation - value comes from dropdown in interface
   set column-count1 120
   set column-count2 80

  set brit-balance 0.7     ; Balance troops using historical precedent
  set column-count1 British-TroopColumns * .6    ;Balanced troops based on user choice for rail fence
  set column-count2 British-TroopColumns * .4    ;Balanced troops based on user choice for hill
  if British-TroopColumns = 160 [
    set x1 110
    set x2 90
  ]
  if British-TroopColumns = 80 [
    set x1 120
    set x2 97
  ]
  if British-TroopColumns = 240 [
    set x1 100
    set x2 82
  ]

  set num-british-form1 (num-british-soldiers * brit-balance)
  set num-british-form2 (num-british-soldiers * (1 - brit-balance))

  ; Setup soldiers (add  soldier creation logic here)
  setup-soldiers                    ; Call to a custom procedure to create soldiers
  set colonist-retreat false

  ;Call Formation Code here after the setup
  brit-assault1
  col-defense1

  set total-brit-80 0
  set total-col-80 0
  set runs-80 0
  set total-brit-160 0
  set total-col-160 0
  set runs-160 0
  set total-brit-240 0
  set total-col-240 0
  set runs-240 0

  reset-ticks
  reset-timer
end

to go

  ;Set the slider for Rows and Troop Balance based on the formation value Selected Above

  ; Check if any part of second formation is near redoubt
  let second-formation-should-stop? false
  ask british with [xcor >= 69 and heading = (atan 3 8) - 90] [  ; Identifying second formation by starting x and heading
    ; Check for redoubt (which has pcolor 25)
    let redoubt-ahead patches in-cone 1.5 60 with [pcolor = 25]
    if any? redoubt-ahead [
      set second-formation-should-stop? true
    ]
  ]

  ask british [
    ifelse xcor >= 69 and heading = (atan 3 8) - 90 [
      ; This is part of second formation
      ifelse second-formation-should-stop? [
        stop-advancing
      ] [
        forward movementSpeed
      ]
    ] [
      ; First formation continues with original logic
      let colonists-ahead colonists in-cone 1.5 60
      ifelse any? colonists-ahead [
        stop-advancing
      ] [
        forward movementSpeed
      ]
    ]
  ]

  if colonist-retreat [

    ask colonists [
      forward movementSpeed
    ]
  ]

  set-targets
  check-can-shoot
  check-hill-speed
  shoot
  ifelse british-wave-retreat [

    check-out-of-shoot-range

  ] [ check-retreat ]

  ifelse (colonist-retreat = false) [
    check-colonist-retreat
  ] [
    ask colonists [
      set movementSpeed (.3 * seconds-per-tick)
      set heading 330
    ]
    check-col-out-of-shoot-range
  ]

  if (british-casualties = num-british-soldiers) [
    user-message (word "British have no soliders left")
    stop
  ]
  if (colonist-casualties = num-colonist-soldiers) [
    user-message (word "Colonists have no soliders left")
    stop
  ]

  update-formation-stats

  tick
end

to check-retreat
  ; compares brits in form 1 compared to tolerance for retreating, also checks if retreat is already happening
  if num-british-form1 < ((1 - british-retreat-percentage) * (brit-balance * num-british-soldiers)) and (british-retreat-form1 = 0) [
    ask british with [formNum = 1] [
      set retreat 1
      set heading (heading - 180)
    ]
    set british-retreat-form1 1
    set wave-trigger-1 true
  ]

  if num-british-form2 < ((1 - british-retreat-percentage) * ((1 - brit-balance) * num-british-soldiers)) and (british-retreat-form2 = 0) [
    ask british with [formNum = 2] [
      set retreat 1
      set heading (heading - 180)
    ]
    set british-retreat-form2 1
    set wave-trigger-2 true
  ]

  ; if both formations are retreating
  if british-retreat-form1 = 1 and british-retreat-form2 = 1 [
    ; have more British attack the hill
    set brit-balance 0.3
    set british-retreat-form1 0
    set british-retreat-form2 0
    set british-wave-retreat true

    ask british [
      ; hide any British that have already fully retreated.
      if (retreat = 1) and ((pxcor = 160) or (pycor = -70)) [
        hide-turtle
        set retreat 0 ; does not need to be hidden again. Fully retreated.
      ]
    ]
  ]
end


; Check if the colonists should retreat. The condition for if colonists should retreat is:
; 1. Most of the colonists have one or less ammunitions left.
; 2. The british soliders have reached the redoubt
to check-colonist-retreat

  let total 0
  let colonistsWithOneOrLessAmmunition 0
  ask colonists [
    if pcolor = 58 or pcolor = 56 [
      if (ammunitionCount >= 3) [ set colonistsWithOneOrLessAmmunition (colonistsWithOneOrLessAmmunition + 1) ]
      set total total + 1
    ]
  ]
  let colonistsCount total
  let majorityColonists ((total / 3) + 1)
  let britishReachedRedoubt false
  if (colonistsWithOneOrLessAmmunition <= majorityColonists) [
    ask british [
      ask patch-here [
        if (pcolor = 25 ) [
          set britishReachedRedoubt true
        ]
      ]
      if (britishReachedRedoubt = true) [ stop ] ; no need to check more British
    ]
    set colonist-retreat true
    ask colonists [
      set retreat 1
    ]
  ]

end

; If the british are all retreating, this function checks that they have finished retreating out of
; shoot range. After they can reform.
to check-out-of-shoot-range
  let allOutOfRange true
  ask colonists [
    ; using max-effective-musket-distance since the British would not know what the
    ; colonist distance-to-shoot commanded range is. They would be able to determine if they were
    ; out of effective range of gunfire since their own weaponry has the same range.
    if (soldierDistance < max-effective-musket-distance ) [
      set allOutOfRange false
    ]
    if (allOutOfRange = false) [ stop ] ; exit out of the ask
  ]
  ifelse (allOutOfRange = true) [
    ; re-call setup, in theory could take parameters to adjust rows and such
    set num-british-soldiers (num-british-form1 + num-british-form2)
    set num-british-form1 (num-british-soldiers * brit-balance)
    set num-british-form2 (num-british-soldiers * (1 - brit-balance))
    brit-assault1
    set british-wave-retreat false
    if (current-wave = 1) [
      user-message "First wave complete! Prepare for the second wave."
    ]
    if (current-wave = 2) [
      set british-retreat-percentage .2
      user-message "Second wave complete! Prepare for the third wave."
    ]
    if (current-wave = 3) [
      user-message "3rd wave complete!"
    ]

    ; Increment the current wave after completing a wave
    set current-wave (current-wave + 1)
  ] [
    ; hide any british that have already fully retreated.
    ask british [
      if (retreat = 1) and ((pxcor = 160) or (pycor = -70)) [
        hide-turtle
        set retreat 0 ; does not need to be hidden again. Fully retreated.
      ]
    ]
  ]
end

to check-col-out-of-shoot-range
  let allOutOfRange true
  ask british [
    ; using max-effective-musket-distance since the British would not know what the
    ; colonist distance-to-shoot commanded range is. They would be able to determine if they were
    ; out of effective range of gunfire since their own weaponry has the same range.
    if (soldierDistance < max-effective-musket-distance ) [
      set allOutOfRange false
    ]
    if (allOutOfRange = false) [ stop ] ; exit out of the ask
  ]
  if (allOutOfRange = true) [
    user-message "Simulation completed, colonists retreated"
    stop
  ]
end

to stop-advancing
  ; Just stay in position and continue other actions
  set heading heading
end

to setup-soldiers
  create-colonists num-colonist-soldiers [
    set color blue
    set firingSpeed (ceiling (1 / colonist-firing-speed))
    ; we used sensitivity analysis to determine an ammunition count that worked. Still fits in historical range.
    let randomAmmunition (2 + random 3)
    set ammunitionCount (randomAmmunition + 1) ; + 1 since random is [).
    set canShoot false
    set hitRate 0
    set movementSpeed 0
    set retreat 0 ; this can get reset at the beginning of the simulation

    ; Set x and y within boundaries
    let safe-xcor (min-pxcor + random (max-pxcor - min-pxcor))
    let safe-ycor (min-pycor + 75) ; make sure  y-coordinate stays within limits
    setxy safe-xcor safe-ycor
  ]

  create-british num-british-soldiers [
    set color red
    set firingSpeed (ceiling (1 / british-firing-speed))
    set ammunitionCount british-ammunition
    set canShoot false
    set hitRate 0
    set movementSpeed .1 * seconds-per-tick ; 1.5 feet per second ~ 1 mph for marching time
    set retreat 0
  ]

  set-targets ; this needs to be called after BOTH British and Colonists are created
end

;Column formation code
to form-columns
  set spacing 0.01
  let y-start min-pycor + spacing ; Start at the bottom of the world, within bounds
  ask british [
    let idx who
    let col idx mod 2 ; Alternate between the two columns
    let row floor (idx / 2)
    let xco col * 10 ; Start x-coordinate at 0 for the first column and 10 for the second column
    setxy xco (y-start + (row * spacing))
  ]
end

;Square formation Code
to brit-assault1
  set spacing .4
  let cols column-count1
  let rows floor num-british-form1 / cols
  let y-position min-pycor ; Ensure the y-coordinate stays within bounds
  let x-start x1 ; Adjust x-start to fit within -150 to 150

  let temp n-of num-british-form1 british

  let idx 0
  let angle 1 / 2
  let up 10
  ask temp [
    let row floor (idx / cols)
    let col idx mod cols
    let x (x-start + (col * spacing))
    let y (y-position + (row * spacing)) + (angle * x) + up
    setxy x y
    set heading (atan (1) 2)
    set heading heading - 90
    set idx idx + 1
    set formNum 1
    set formRows rows
    set retreat 0
    show-turtle
  ]

  set spacing .33
  set cols column-count2
  set rows floor num-british-form2 / cols
  set x-start x2

  let temp2 other british with [not member? self temp]

  set idx 0
  set angle 3 / 8
  set up -10
  ask temp2 [
    let row floor (idx / cols)
    let col idx mod cols
    let x (x-start + (col * spacing))
    let y (y-position + (row * spacing)) + (angle * x) + up
    setxy x y
    set heading (atan (3) 8)
    set heading heading - 90
    set idx idx + 1
    set formNum 2
    set formRows rows
    set retreat 0
    show-turtle
  ]
end

to col-defense1
  let angle 1 / 2
  let balance .7
  let temp n-of (num-colonist-soldiers * balance) colonists
  let cols 130
  let rows floor (num-colonist-soldiers * balance) / cols

  let x-start 54
  let y-position 0
  let idx 0
  let up 1
  set spacing .3
  ask temp [
    let row floor (idx / cols)
    let col idx mod cols
    let x (x-start + (col * spacing))
    let y (y-position + (row * spacing)) + (angle * x) + up
    setxy x y
    set heading (atan (1) 2)
    set heading heading - 90
    set idx idx + 1
    set formNum 1
    set formRows rows / 2
  ]


  set spacing .2

  set rows 8
  set cols floor (num-colonist-soldiers * (1 - balance)) / rows
  set x-start 7

  let temp2 other colonists with [not member? self temp]

  set idx 0
  set angle 3 / 8
  set up -12
  let redoubtTroops 200 ;number of troops to go in redoubt, rest hides behind the side of the hill
  ask temp2 [
    ifelse idx < redoubtTroops [
      let row floor (idx / cols)
      let col idx mod cols
      let x (x-start + (col * spacing))
      let y (up + (row * spacing)) + (angle * x)
      setxy x y
      set heading (atan (3) 8)
      set heading heading - 90
      set idx idx + 1
      set formNum 2
      set formRows rows / 2
    ] [
      set spacing .3
      set angle (-3 / 8)
      set x-start 25
      set up 8
      let row floor (idx / cols)
      let col idx mod cols
      let x (x-start + (col * spacing))
      let y (up + (row * spacing)) + (angle * x)
      setxy x y
      ; perpendicular with the south east side of the hill to prepare for ambush
      set heading (atan (-3) 8)
      set heading heading - 90
      set idx idx + 1
      set formNum 3
      set formRows rows
    ]
  ]

end

; set the target soldier and distance away for each soldier.
to set-targets
  ask colonists [
    ; get the closest Brit to the Colonist
    set closestSoldier min-one-of british [ distance myself ]

    ifelse closestSoldier != nobody [
      ; check the distance between the Brit and the Colonist
      set soldierDistance distance closestSoldier
      set soldierDistance (soldierDistance * 15) ; each patch is 15 feet
    ] [
      set soldierDistance (colonist-distance-to-shoot + 1)  ; edge case for if there is no closest soldier; set distance out of range.
    ]
  ]

  ask british [
    ; get the closest Brit to the Colonist
    set closestSoldier min-one-of colonists [ distance myself ]

    ifelse closestSoldier != nobody [
      ; check the distance between the Brit and the Colonist
      set soldierDistance distance closestSoldier
      set soldierDistance (soldierDistance * 15) ; each patch is 15 feet
    ] [
      set soldierDistance (max-effective-musket-distance + 1) ; edge case for if there is no closest soldier; set distance out of range.
    ]
  ]
end

; a function to check if the soldier can shoot. Checks if a soldier can shoot based on formation,
; distance to shoot range, and if the closest solider is visibile (no hill in the way).
to check-can-shoot
  ask colonists [
    ; use form rows so that only one row can shoot at a time
    let randomRoll random (firingSpeed * formRows)
    ifelse (soldierDistance < colonist-distance-to-shoot) and (ammunitionCount > 0) and (randomRoll = 1) and (colonist-retreat = false) [
      set canShoot true
    ] [
      set canShoot false
    ]

    ; checks to see if hill is in the way
    if closestSoldier != nobody [

      let oppx 0
      let oppy 0
      ask closestSoldier [
        set oppx xcor
        set oppy ycor
      ]
      let currTerrain pcolor
      let oppTerrain 1
      ask closestSoldier [ set oppTerrain pcolor]

      let bigger (max list currTerrain oppTerrain)
      ; customized to current scenario, if colonial troops are moved to different part of the hill THIS HAS TO CHANGE
      if bigger = 56 [
        ; if two parts of the hill are in between, then can shoot is set to false
        let counter 0

        let sw test-intersection xcor ycor oppx oppy (-3 / 8) -15 -88 13.33
        if sw [ set counter counter + 1 ]

        let nw test-intersection xcor ycor oppx oppy (3 / 8) 51 -88 -53.33
        if nw [ set counter counter + 1 ]

        let sea test-intersection xcor ycor oppx oppy (3 / 8) -25 13.33 48
        if sea [ set counter counter + 1 ]

        let ne test-intersection xcor ycor oppx oppy (-3 / 8) 8 -53.33 48
        if ne [ set counter counter + 1 ]

        if counter >= 2 [
          set canShoot false
        ]
      ]
    ]
  ]

  ask british [
    let randomRoll random (firingSpeed * formRows)
    ifelse (soldierDistance < max-effective-musket-distance) and (ammunitionCount > 0) and (randomRoll = 1) and (retreat = 0) [
      set canShoot true
    ] [
      set canShoot false
    ]

    if closestSoldier != nobody [

      let oppx 0
      let oppy 0
      ask closestSoldier [
        set oppx xcor
        set oppy ycor
      ]
      let currTerrain pcolor
      let oppTerrain 1
      ask closestSoldier [ set oppTerrain pcolor]

      let bigger (max list currTerrain oppTerrain)
      ifelse bigger = 56 [
        let counter 0

        let sw test-intersection xcor ycor oppx oppy (-3 / 8) -15 -88 13.33
        if sw [ set counter counter + 1 ]

        let nw test-intersection xcor ycor oppx oppy (3 / 8) 51 -88 -57.33
        if nw [ set counter counter + 1 ]

        let sea test-intersection xcor ycor oppx oppy (3 / 8) -25 13.33 44
        if sea [ set counter counter + 1 ]

        let ne test-intersection xcor ycor oppx oppy (-3 / 8) 8 -57.33 44
        if ne [ set counter counter + 1 ]

        if counter >= 2 [
          set canShoot false
        ]

      ] []
    ]
  ]

end


to check-hill-speed
  ask british [
    let currentPatch pcolor
    let verticalDistance 0 ; Default vertical distance
    let flat-speed 0.1 * seconds-per-tick ; Flat ground speed
    let horizontalDistance 1 ; Default horizontal distance for flat ground

    ; Set vertical and horizontal distances based on current patch color
    if currentPatch = 54 [
      set verticalDistance 0
      set horizontalDistance 1 ; Flat ground, normal horizontal distance
    ]
    if currentPatch = 55 [
      set verticalDistance 5
      set horizontalDistance 0.9
    ]
    if currentPatch = 56 [
      set verticalDistance 10
      set horizontalDistance 0.8
    ]
    if currentPatch = 57 [
      set verticalDistance 15
      set horizontalDistance 0.7
    ]
    if currentPatch = 58 [
      set verticalDistance 20
      set horizontalDistance 0.6
    ]

    ; Calculate equivalent distance using Scarf's rule
    let alpha 7.92
    let equivalentDistance horizontalDistance + (alpha * verticalDistance)

    ; Set movementSpeed based on equivalent distance and patch color
    if currentPatch = 53 [
      set movementSpeed flat-speed ; Flat ground speed
    ]
    if currentPatch = 54 [
      set movementSpeed flat-speed / (1 + (equivalentDistance / 10)) ; Adjust speed for flat ground
    ]
    if currentPatch = 55 [
      set movementSpeed flat-speed / (1 + (equivalentDistance / 15)) ; Adjust speed based on incline
    ]
    if currentPatch = 56 [
      set movementSpeed flat-speed / (1 + (equivalentDistance / 20)) ; Adjust speed based on incline
    ]
    if currentPatch = 57 [
      set movementSpeed flat-speed / (1 + (equivalentDistance / 25)) ; Adjust speed based on incline
    ]
    if currentPatch = 58 [
      set movementSpeed flat-speed / (1 + (equivalentDistance / 30)) ; Adjust speed based on incline
    ]

    ; Move the soldiers forward based on the calculated movement speed
    forward movementSpeed
  ]
end

to shoot
  ; if the soldier is going to shoot, we want to calculate hit rate (we don't need to do this if they aren't shooting, save performance)
  check-hit-rate

  ask colonists [
    if canShoot [
      set ammunitionCount (ammunitionCount - 1) ; take the shot, so decrement the ammunition

      let randomRoll random 100 ; this will get a number from [0, 100)
      if (hitRate > 0) and (randomRoll < hitRate + 1) [
                ; It is possible the solider was also another solider's closest soldier and its already dead. Handle crash exception.
        if closestSoldier != nobody [
          let form 0
          ask closestSoldier [
            set form formNum    ; checks to see which formation the British troop is in
            die
          ]
          set british-casualties (british-casualties + 1)
          if form = 1 [
            set num-british-form1 (num-british-form1 - 1)
          ]
          if form = 2 [
            set num-british-form2 (num-british-form2 - 1)
          ]
        ]
      ]
    ]
  ]

  ask british [
    if canShoot [
      set ammunitionCount (ammunitionCount - 1) ; take the shot, so decrement the ammunition

      let randomRoll random 100 ; this will get a number from [0, 100)

      if (hitRate > 0) and (randomRoll < hitRate + 1) [
        ; It is possible the solider was also another solider's closest soldier and its already dead. Handle crash exception.
        if closestSoldier != nobody [
          ask closestSoldier [ die ]
          set colonist-casualties (colonist-casualties + 1)
        ]
      ]
    ]
  ]
end

; the function to check the hit rate of the soldiers.
to check-hit-rate
  ask colonists [
    ; Assuming a uniform hill incline, which is not exactly the but on average it should even out.
    ; If this changes, we need to make separate equation for uphill and downhill. Since right now it is split
    let uphillDownhillFeet (total-hill-feet / 2)
    let uphillDownhillFeetRatio soldierDistance / uphillDownhillFeet
    ; per Jason the topographical map has our height at ~65ft; get the % of the incline depending on the % of the soldierDistance
    let uphillDownhillHeightRatio (65 * uphillDownhillFeetRatio)

    ifelse (soldierDistance = 0) [ set hitRate 100 ] [
      ; use the pythagorean theorum to get the hypotenuse
      let hypotenuse (uphillDownhillHeightRatio * uphillDownhillHeightRatio) + (soldierDistance * soldierDistance)
      set hypotenuse (sqrt hypotenuse)

      ; use sohcahtoa, adjacent / hypotenuse
      let cosine (soldierDistance / hypotenuse)

      ; yard * 3 is the value in feet.
      let trueBallisticDistance (cosine * soldierDistance)
      (ifelse trueBallisticDistance < 75 [
        set hitRate 100
        ]
        trueBallisticDistance <= 246 [
          set hitRate 60
        ]
        trueBallisticDistance <= 438 [
          set hitRate 40
        ]
        trueBallisticDistance <= 738 [
          set hitRate 25
        ]
        trueBallisticDistance <= 984 [
          set hitRate 20
        ]
        [ set hitRate 0 ])
    ]
  ]

   ask british [
    ; Assuming a uniform hill incline, which is not exactly the but on average it should even out.
    ; If this changes, we need to make separate equation for uphill and downhill. Since right now it is split
    let uphillDownhillFeet (total-hill-feet / 2)
    let uphillDownhillFeetRatio soldierDistance / uphillDownhillFeet
    ; per Jason the topographical map has our height at ~65ft; get the % of the incline depending on the % of the soldierDistance
    let uphillDownhillHeightRatio (65 * uphillDownhillFeetRatio)

    ifelse (soldierDistance = 0) [ set hitRate 100 ] [
      ; use the pythagorean theorum to get the hypotenuse
      let hypotenuse (uphillDownhillHeightRatio * uphillDownhillHeightRatio) + (soldierDistance * soldierDistance)
      set hypotenuse (sqrt hypotenuse)

      ; use sohcahtoa, adjacent / hypotenuse
      let cosine (soldierDistance / hypotenuse)

      ; yard * 3 is the value in feet.
      let trueBallisticDistance (cosine * soldierDistance)
      (ifelse trueBallisticDistance < 75 [
        set hitRate 100
        ]
        trueBallisticDistance <= 246 [
          set hitRate 60
        ]
        trueBallisticDistance <= 438 [
          set hitRate 40
        ]
        trueBallisticDistance <= 738 [
          set hitRate 25
        ]
        trueBallisticDistance <= 984 [
          set hitRate 20
        ]
        [ set hitRate 0 ])
    ]

    ; find the equation of the line given two soldiers positions, use chain fence equation, find determinant to see intersection point, check to see that the firing line goes through it
    if closestSoldier != nobody [
      let oppx 0
      let oppy 0
      ask closestSoldier [
        set oppx xcor
        set oppy ycor
      ]
      ; checks if rail is in the way
      let rail test-intersection xcor ycor oppx oppy .5 0 54 94
      if rail [ set hitRate hitRate * .20  ]

      ;checks if either part of the redoubt is in the way
      let redoubtWest test-intersection xcor ycor oppx oppy (-3 / 8) -8 -1 9
      if redoubtWest [ set hitRate hitRate * .05 ]

      let redoubtSouth test-intersection xcor ycor oppx oppy (3 / 8) -14 8 19
      if redoubtSouth [ set hitRate hitRate * .05 ]

      let nehillcover test-intersection xcor ycor oppx oppy (-3 / 8) 8 -53.33 48
      if nehillcover [
        set hitRate hitRate * .15
      ]

    ]
  ]
end

; Function to setup the hill terrain and fortifications
to setup-terrain
  let x min [pxcor] of patches
  let xmax max [pxcor] of patches
  let y min [pycor] of patches
  let ymin min [pycor] of patches
  let ymax max [pycor] of patches

  while [x <= xmax] [
    set y ymin
    while [y <= ymax] [
      let p patch x y
      ask p [set pcolor 97]
      if (y >= int ((-4.0 / 3.0) * x - 240)) and (y <= int ((-2.0 / 6.7) * x + 100)) and (y >= int ((2.0 / 5.0) * x - 110)) [
        ask p [set pcolor 53]
      ]
      ; Breeds Hill
      if ((y > int ((-3.0 / 8.0) * x - 31)) and (y < int ((-3.0 / 8.0) * x + 27)) and (y > int ((3.0 / 8.0) * x - 41)) and (y < int ((3.0 / 8.0) * x + 67))) [
        ask p [set pcolor 54]
      ]
      ; Elevation of Breeds Hill
      if ((y > int ((-3.0 / 8.0) * x - 23)) and (y < int ((-3.0 / 8.0) * x + 19)) and (y > int ((3.0 / 8.0) * x - 33)) and (y < int ((3.0 / 8.0) * x + 59))) [
        ask p [set pcolor 55]
      ]
      if ((y > int ((-3.0 / 8.0) * x - 19)) and (y < int ((-3.0 / 8.0) * x + 15)) and (y > int ((3.0 / 8.0) * x - 29)) and (y < int ((3.0 / 8.0) * x + 55))) [
        ask p [set pcolor 56]
      ]
      if ((y > int ((-3.0 / 8.0) * x - 15)) and (y < int ((-3.0 / 8.0) * x + 8)) and (y > int ((3.0 / 8.0) * x - 25)) and (y < int ((3.0 / 8.0) * x + 51))) [
        ask p [set pcolor 57]
      ]
      if ((y > int ((-3.0 / 8.0) * x - 10)) and (y < int ((-3.0 / 8.0) * x + 6)) and (y > int ((3.0 / 8.0) * x - 17)) and (y < int ((3.0 / 8.0) * x + 43))) [
        ask p [set pcolor 58]
      ]
      ; Redoubt
      if ((y = int ((-3.0 / 8.0) * x - 8)) and (x > -1) and (x < 9)) [
        ask p [set pcolor 25]
      ]
      if ((y = int ((3.0 / 8.0) * x - 14)) and (x > 8) and (x < 19)) [
        ask p [set pcolor 25]
      ]
      ; Rail fence
      if ((y = int ((3.0 / 6.0) * x)) and (x > 54) and (x < 94)) [
        ask p [set pcolor 45]
      ]
      set y y + 1
    ]
    set x x + 1
  ]
end

; this function tests if there is some sort of environmental boundary between two points
; low is the lower bound of the boundary interval, high is upper bound
; https://www.geeksforgeeks.org/program-for-point-of-intersection-of-two-lines/
to-report test-intersection [currx curry oppx oppy m2 b2 low high]
  let small (min list currx oppx)
  let big (max list currx oppx)

  let m1 ((curry - oppy) / (currx - oppx))
  let b1 (curry - m1 * currx)

  set m1 (-1 * m1)
  set m2 (-1 * m2)

  let deter (m1 - m2)
  if deter != 0 [

    let x ((b1 - b2) / deter)
    ; check if the intersection point is within both the boundary interval and within the agent to agent shot
    if x > low and x < high and x >= small and x <= big [
      report true
    ]
  ]
  report false
end

to update-formation-stats
  if British-TroopColumns = 80 [
    set total-brit-80 total-brit-80 + british-casualties
    set total-col-80 total-col-80 + colonist-casualties
    set runs-80 runs-80 + 1
    set avg-brit-80 total-brit-80 / runs-80
    set avg-col-80 total-col-80 / runs-80
  ]
  if British-TroopColumns = 160 [
    set total-brit-160 total-brit-160 + british-casualties
    set total-col-160 total-col-160 + colonist-casualties
    set runs-160 runs-160 + 1
    set avg-brit-160 total-brit-160 / runs-160
    set avg-col-160 total-col-160 / runs-160
  ]
  if British-TroopColumns = 240 [
    set total-brit-240 total-brit-240 + british-casualties
    set total-col-240 total-col-240 + colonist-casualties
    set runs-240 runs-240 + 1
    set avg-brit-240 total-brit-240 / runs-240
    set avg-col-240 total-col-240 / runs-240
  ]
end

to reset-battle
  ; Reset battle-specific variables but keep statistics
  set colonist-casualties 0
  set british-casualties 0
  set current-wave 1
  set wave-trigger-1 false
  set wave-trigger-2 false
  set british-wave-retreat false

  ; Reset soldiers
  clear-turtles
  setup-soldiers
  brit-assault1
  col-defense1

  reset-ticks
  reset-timer
end
@#$#@#$#@
GRAPHICS-WINDOW
277
10
1248
442
-1
-1
3.0
1
10
1
1
1
0
0
0
1
-160
160
-70
70
1
1
1
ticks
30.0

BUTTON
63
11
126
44
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
135
10
198
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
46
55
218
88
distance-to-shoot
distance-to-shoot
30
300
90.0
30
1
NIL
HORIZONTAL

MONITOR
35
137
118
182
NIL
count british
0
1
11

MONITOR
140
136
238
181
NIL
count colonists
0
1
11

SLIDER
46
96
218
129
British-TroopColumns
British-TroopColumns
80
240
160.0
80
1
NIL
HORIZONTAL

PLOT
8
348
264
509
Colonist Casualties Over Time
Time (Ticks)
Colonist Deaths
0.0
800.0
0.0
1500.0
true
false
"" ""
PENS
"default" 1.0 0 -14454117 true "" "plot colonist-casualties"

PLOT
8
190
264
343
British Casualties Over Time
Time (Ticks)
British Deaths
0.0
800.0
0.0
2000.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot british-casualties"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Average Casualties" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>british-casualties</metric>
    <metric>colonist-casualties</metric>
    <enumeratedValueSet variable="British-TroopBal">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="formations">
      <value value="&quot;Line-Custom&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-to-shoot">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="British-TroopColumns">
      <value value="80"/>
      <value value="160"/>
      <value value="240"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
