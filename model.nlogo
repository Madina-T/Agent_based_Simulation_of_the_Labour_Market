breed [persons person]
breed [companies company]
breed [matchings matching]

persons-own [ skills location salary employed employer time_as_employee time_as_unemployee age]
companies-own [ skills location salary filled employee time_as_vacant number_of_jobs jobs]
matchings-own [unemployed vacant]


globals[

  matching_id
  nb_pairs_max
  max-salary
  mean-salary
  vacancy_rate_list
  unemployment_rate_list
  max-age
  min_legal_age
  u_to_plot
  v_to_plot
  list_u
  list_v
  U_list
  V_list
  convergence_treshold
  frictional_unemployment
  structural_unemployment
  natural_unemployment
  salary_min
  hiring_level
  firing_level
  hiring_rate
  firing_rate
  max_number_of_jobs
]

to setup
  clear-all
  set hiring_level 0
  set firing_level 0
  set max-salary 100
  set mean-salary 50
  set nb_pairs_max 100
  set vacancy_rate_list []
  set unemployment_rate_list []
  set u_to_plot []
  set v_to_plot []
  set U_list (List 100 200 300 400)
  set V_list (List 100 200 300 400)
  set convergence_treshold 0.1
  set max-age 100
  set max_number_of_jobs 10

  create-persons number_of_persons ; create the persons, then initialize their variables
  [
    set shape  "person"
    set color red
    set size 1.5  ; easier to see
    set label-color blue - 2
    setxy random-xcor random-ycor
    set skills (list (one-of [ true false ]) (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ]))
    set salary mean-salary + random-float ( max-salary - mean-salary)
    set employed false
    set employer nobody
    set time_as_employee 0
    set time_as_unemployee 0
    set age 0

  ]

  create-companies number_of_companies ; create the companies, then initialize their variables
  [
    set shape "triangle"
    set color red
    set size 1  ; easier to see
    setxy random-xcor random-ycor
    set skills (list (one-of [ true false ]) (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ]))
    set salary mean-salary + random-float ( max-salary - mean-salary)
    set filled false
    set employee nobody
    set time_as_vacant 0
    set number_of_jobs 1 + random max_number_of_jobs

    set jobs []
    foreach range number_of_jobs [ i ->
      let skill (List (one-of [ true false ]) (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ]))
      let sal mean-salary + random-float ( max-salary - mean-salary)
      set jobs lput (List (False) (nobody) (skill) (sal )  ) jobs
    ]
  ]

  create-matchings 1
  [
    set matching_id who
    set unemployed []
    set vacant []
  ]

  reset-ticks
end



to go

  ask persons[
    persons_procedure
  ]
  ask companies[
    companies_procedure
  ]
  ask matchings[
    matching_procedure
  ]
  ask matching matching_id [
    if number_of_persons = 0 or number_of_companies = 0 [
      stop
    ]
    set vacancy_rate_list lput ((length vacant) / number_of_persons) vacancy_rate_list
    set unemployment_rate_list lput ((length unemployed) / number_of_persons) unemployment_rate_list
    ;plotxy ((length vacant) / number_of_persons)  ((length unemployed) / number_of_persons)

  ]

  if choose_extension = "open_system" or choose_extension = "both" [
    if random-float 1 < birth_rate[
      ;let new_born ( random ( number_of_persons / 2 ) ) * birth_rate
      let new_born random ( 100 - number_of_persons)
      set number_of_persons ( number_of_persons + new_born )
      create-persons new_born; create the persons, then initialize their variables
      [
        set shape  "person"
        set color red
        set size 1.5  ; easier to see
        set label-color blue - 2
        setxy random-xcor random-ycor
        set skills (list (one-of [ true false ]) (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ]))
        set salary mean-salary + random-float ( max-salary - mean-salary)
        set employed false
        set employer nobody
        set time_as_employee 0
        set time_as_unemployee 0
        set age 0

      ]
    ]


    if random-float 1 <  company_creation_rate[
      let new_born 1
      set number_of_companies ( number_of_companies + new_born )

      create-companies new_born ; create the companies, then initialize their variables
      [
        set shape "triangle"
        set color red
        set size 1  ; easier to see
        setxy random-xcor random-ycor
        set skills (list (one-of [ true false ]) (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ]))
        set salary mean-salary + random-float ( max-salary - mean-salary)
        set filled false
        set employee nobody
        set time_as_vacant 0
        set number_of_jobs 1 + random max_number_of_jobs

        set jobs []
        foreach range number_of_jobs [ i ->
          let skill (List (one-of [ true false ]) (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ]))
          let sal mean-salary + random-float ( max-salary - mean-salary)
          set jobs lput (List (False) (nobody) (skill) (sal )  ) jobs
        ]
      ]
    ]

  ]
  tick
end

to persons_procedure
  ifelse choose_extension = "none" [
    let person_id who
    if not employed [
      ask matching matching_id [
        if not member? person_id unemployed [
          set unemployed lput person_id unemployed
        ]
      ]
    ]
  ][

    ifelse choose_extension = "open_system" [
      let person_id who

      set age age + 1


      if (age > random max-age)[
        let myself_ who
        ask matching matching_id [
          if member? myself_ unemployed [
            set unemployed (remove myself_ unemployed)
          ]
        ]
        if employed [
          ask company employer [
            set filled False
            set color red
            ask my-links [die]
          ]
        ]
        set number_of_persons ( number_of_persons - 1 )
        die
      ]
      ifelse not employed and age > min_legal_age  [
        set time_as_unemployee ( time_as_unemployee + 1 )
        ask matching matching_id [
          if not member? person_id unemployed [
            set unemployed lput person_id unemployed
          ]
        ]
      ][
        if employed [
          ;; Processus de demission
          set time_as_employee ( time_as_employee + 1 )
          let sim compute_similarities_person ( person who )  (company employer )
          let nb_vacant 0
          ask matching matching_id [
            set nb_vacant length vacant
          ]
          set nb_vacant nb_vacant - (random nb_vacant)
          let time-max 5000
          let proba random-float (( time_as_employee + sim + nb_vacant) /( time-max + 1 + number_of_companies))
          set time_as_employee 0
          if proba > resignation_treshold [
            set employed False
            set color red

            ask company employer [
              set time_as_vacant 0
              set filled False
              set color red
              ask my-links [die]
            ]
          ]
        ]
      ]

    ][
      let person_id who

      set age age + 1
      ;Death
      if choose_extension = "both" [
        if (age > random max-age)[
          let myself_ who
          ask matching matching_id [
            if member? myself_ unemployed [
              set unemployed (remove myself_ unemployed)
            ]
          ]
          if employed [
            ask my-links [die]
            ask company employer [
              ifelse choose_extension != "both" [
                set filled False
                set color red
                ask my-links [die]
              ][
                foreach range length jobs [ i ->
                  let x item i jobs
                  if (item 1 x) = myself_ [
                    set x replace-item 0 x (False)
                    set jobs replace-item i jobs x
                    set number_of_jobs number_of_jobs + 1
                    set filled False
                    set color gray
                    if number_of_jobs < length jobs [
                      set color red
                    ]


                  ]
                ]
              ]
            ]
          ]

          set number_of_persons ( number_of_persons - 1 )
          die
        ]
      ]
      ifelse not employed and ( age > min_legal_age or ( choose_extension != "open_system" or choose_extension != "both" )) [
        set time_as_unemployee ( time_as_unemployee + 1 )
        ask matching matching_id [
          if not member? person_id unemployed [
            set unemployed lput person_id unemployed
          ]
        ]
      ][
        if not is-turtle? employer  [
          set employed False
        ]
        if employed [
          let myself_ who
          ifelse choose_extension = "none" or choose_extension = "open_system" [
            ;; Processus de demission
            set time_as_employee ( time_as_employee + 1 )
            let sim compute_similarities_person ( person who )  (company employer )
            let nb_vacant 0
            ask matching matching_id [
              set nb_vacant length vacant
            ]
            set nb_vacant nb_vacant - (random nb_vacant)
            let time-max 5000
            let proba random-float (( time_as_employee + sim + nb_vacant) /( time-max + 1 + number_of_companies))
            set time_as_employee 0
            if proba > resignation_treshold [
              set employed False
              set color red

              ask company employer [
                set time_as_vacant 0
                set filled False
                set color red
                ask my-links [die]
              ]
            ]
          ][

            ask company employer [
              foreach range length jobs [ i ->
                let x item i jobs
                if (item 1 x) = myself_ [
                  set skills (item 2 x)
                  set salary (item 3 x)
                  let sim compute_similarities_person ( person myself_ )  (company who )
                  let nb_vacant 0
                  ask matching matching_id [
                    set nb_vacant length vacant
                  ]
                  set nb_vacant nb_vacant - (random nb_vacant)
                  let time-max 5000
                  ask person myself_ [
                    let proba random-float (( time_as_employee + sim + nb_vacant) /( time-max + 1 + number_of_companies))
                    set time_as_employee 0
                    if proba > resignation_treshold [
                      set employed False
                      set color red
                      ask person myself_  [
                        ask my-links [die]
                      ]
                      ask company employer [
                        set x replace-item 1 x (False)
                        set jobs replace-item i jobs x
                        set time_as_vacant 0
                        set number_of_jobs (number_of_jobs + 1)
                        set filled False
                        set color gray
                        if number_of_jobs = length jobs [
                          set color red
                        ]

                      ]
                    ]
                  ]
                ]
              ]
            ]

          ]
        ]
      ]
  ]]
end





to companies_procedure
  ifelse choose_extension = "none" [
    let company_id who
    ifelse not filled [
      ask matching matching_id [
        if not member? company_id vacant [
          set vacant lput company_id vacant
        ]
      ]
    ][
      ask person employee [
        let skills_unemployee skills
        let skills_company  ([skills] of (company employer))
        let sim 0
        foreach range (length skills_unemployee)[i ->
          if (item i skills_unemployee) = (item i skills_company)[
            set sim (sim + 1)
          ]
        ]
        set sim sim / 5

        let prod sim + (random-float (2) - 1) * max_productivity_fluctuation * sim

        if (random-float 1 < unexpected_firing) or (sim < firing_quality_treshold) [
          set firing_level ( firing_level + 1 )
          if (( count persons with [employed]) != 0 ) [
            set firing_rate firing_level / ( count persons with [employed])
          ]
          set employed False
          set color red

          ask company employer [
            set filled False
            set color red
            ask my-links [die]
          ]

        ]

      ]


    ]
  ]
  [
    ifelse choose_extension  = "open_system" [
      let company_id who
      ifelse not filled [
        set time_as_vacant time_as_vacant + 1
        ask matching matching_id [
          if not member? company_id vacant [
            set vacant lput company_id vacant
          ]
        ]
        let time-max 500
        if random-float 1 < time_as_vacant / ( ticks + 1 ) [
          let myself_ who
          ask matching matching_id [
            if member? myself_ vacant [
              set vacant (remove myself_ vacant)
            ]
          ]
          if filled [
            ask person employee [
              set employed False
              set color red
              ask my-links [die]
            ]
          ]
          set number_of_companies ( number_of_companies - 1 )
          die
        ]
      ][
        ask person employee [
          let skills_unemployee skills
          let skills_company  ([skills] of (company employer))
          let sim 0
          foreach range (length skills_unemployee)[i ->
            if (item i skills_unemployee) = (item i skills_company)[
              set sim (sim + 1)
            ]
          ]
          set sim sim / 5

          let prod sim + (random-float (2) - 1) * max_productivity_fluctuation * sim

          if (random-float 1 < unexpected_firing) or (sim < firing_quality_treshold) [
            set firing_level ( firing_level + 1 )
            if (( count persons with [employed]) != 0 ) [
              set firing_rate firing_level / ( count persons with [employed])
            ]
            set time_as_employee 0
            set employed False
            set color red

            ask company employer [
              set time_as_vacant 0
              set filled False
              set color red
              ask my-links [die]
            ]

          ]

        ]


      ]
    ][
        set number_of_jobs 0
          foreach jobs [ x ->
            if not item 0 x [
              set filled False
              set number_of_jobs number_of_jobs + 1
            ]
          ]

        let company_id who
        if (not filled  ) [
          set time_as_vacant time_as_vacant + 1
          ask matching matching_id [
            if not member? company_id vacant [
              set vacant lput company_id vacant
            ]
          ]

          ;Death
          if choose_extension = "both" [
            if random-float 1 < time_as_vacant / ( ticks + 1 ) [
              let myself_ who

              ifelse choose_extension = "both" [
                foreach jobs [x ->
                  if item 0 x [
                    ask person (item 1 x) [
                      set employed False
                      set color red
                      ask my-links [die]
                    ]

                  ]
                ]

              ][
                if filled [
                  ask person employee [
                    set employed False
                    set color red
                    ask my-links [die]
                  ]
                ]
              ]
              ask matching matching_id [
                if member? myself_ vacant [
                  set vacant (remove myself_ vacant)
                ]
              ]
              set number_of_companies ( number_of_companies - 1 )
              die
            ]
          ]
        ]
        if (number_of_jobs < length jobs) [
          ;Processus de virement
            foreach range length jobs  [i ->
              let x item i jobs
          let myself_ who
              if (item 0 x ) [
                ask person (item 1 x) [

                  let skills_unemployee skills
                  let skills_company  (item 2 x)
                  let sim 0
                  foreach range (length skills_unemployee)[j ->
                    if (item j skills_unemployee) = (item j skills_company)[
                      set sim (sim + 1)
                    ]
                  ]
                  set sim sim / 5

                  let prod sim + (random-float (2) - 1) * max_productivity_fluctuation * sim

                  if (random-float 1 < unexpected_firing) or (sim < firing_quality_treshold) [
                    set firing_level ( firing_level + 1 )
                    if (( count persons with [employed]) != 0 ) [
                      set firing_rate firing_level / ( count persons with [employed])
                    ]
                    set time_as_employee 0
                    set employed False
                    set color red
                    ask my-links [die]
                    if myself_ = employer [
                    ask company employer [
                      set number_of_jobs (number_of_jobs + 1)

                      set x replace-item 0 x (False)
                      set jobs replace-item i jobs x
                      set time_as_vacant 0
                      set filled False
                      set color gray
                      if number_of_jobs = length jobs [
                        set color red
                      ]

                    ]
                    let employer_ employer
                ]

                  ]

              ]]
            ]

  ]]]
end


to matching_procedure
  ifelse choose_extension = "none" or choose_extension = "open_system" [
    let nb_pair (min (List  nb_pairs_max (length vacant) (length unemployed)))
    let considered_vacant n-of nb_pair vacant
    let considered_unemplyed n-of nb_pair unemployed
    set hiring_level 0
    set firing_level 0
    let unemployed_persons length unemployed
    foreach considered_vacant[[x] ->
      foreach considered_unemplyed[[y] ->
        let unemployee_ (person y)
        let company_ (company x)
        let similarity1 (compute_similarities_person unemployee_ company_)
        let similarity2 (compute_similarities_company unemployee_ company_)

        if member? x vacant and member? y unemployed [
          ifelse (abs (similarity1 - similarity2) <= exceptional_matching) or (((similarity1 + similarity2) / 2 )>= matching_quality_treshold) [
            set vacant (remove x vacant)
            set unemployed (remove y unemployed)
            set hiring_level ( hiring_level + 1 )
            if (length unemployed != 0 ) [
              set hiring_rate hiring_level / (unemployed_persons)
            ]
            ask person y [
              set color green
              set employed True
              set employer x
              set time_as_employee 0

            ]
            ask company x [
              set color green
              set filled True
              create-link-with (person y)
              set employee y
              set time_as_vacant 0
            ]

          ]
          [
            set structural_unemployment ( structural_unemployment + 1)
          ]
        ]

    ]]
  ][
    let nb_pair (min (List  nb_pairs_max (length vacant) (length unemployed)))
    let considered_vacant n-of nb_pair vacant
    let considered_unemplyed n-of nb_pair unemployed
    set hiring_level 0
    set firing_level 0
    let unemployed_persons length unemployed

    foreach considered_vacant[[x] ->
      foreach considered_unemplyed[[y] ->
        let unemployee_ (person y)
        let company_ (company x)
        let job_nb 0
        if choose_extension != "none" or choose_extension != "open_system" [
          ask company_ [
            let done False
            foreach range length jobs [i ->
              if not done [
                let z item i jobs
                if not item 0 z [
                  set skills (item 2 z)
                  set salary (item 3 z)
                  set job_nb i
                  set done  True
                ]
              ]
            ]
          ]
        ]
        let similarity1 (compute_similarities_person unemployee_ company_)
        let similarity2 (compute_similarities_company unemployee_ company_)
        if member? x vacant and member? y unemployed [
          ifelse (abs (similarity1 - similarity2) <= exceptional_matching) or (((similarity1 + similarity2) / 2 )>= matching_quality_treshold) [
            let remove_vacant False
            ask company x [
              set number_of_jobs (number_of_jobs - 1)

              if number_of_jobs = 0 [
                set remove_vacant True
              ]
            ]


            set unemployed (remove y unemployed)
            set hiring_level ( hiring_level + 1 )
            if (length unemployed != 0 ) [
              set hiring_rate hiring_level / (unemployed_persons)
            ]
            ask person y [
              set color green
              set employed True
              set employer x
              set time_as_employee 0

            ]
            ifelse choose_extension = "none" or choose_extension = "open_system" or remove_vacant[

              set vacant (remove x vacant)
              ask company x [
                set color green
                set filled True
                create-link-with (person y)
                set employee y
                set time_as_vacant 0
              ]
            ][
              ask company x [

                let z item job_nb jobs
                set z replace-item 0 z (True)
                set z replace-item 1 z (y)
                set jobs replace-item job_nb jobs z
                set color gray

                create-link-with (person y)
                set time_as_vacant 0
              ]
            ]

          ]
          [
            set structural_unemployment ( structural_unemployment + 1)
          ]
        ]

    ]]
  ]
end


to-report compute_similarities_person [unemployee_ company_ ]

  let skills_unemployee ([skills] of unemployee_)
  let skills_company  ([skills] of company_)
  let sim 0
  foreach range (length skills_unemployee)[i ->
    if (item i skills_unemployee) = (item i skills_company)[
      set sim (sim + 1)
    ]
  ]
  set sim sim / 5

  let x1 [xcor] of unemployee_
  let y1 [ycor] of unemployee_
  let x2 [xcor] of company_
  let y2 [ycor] of company_
  let max-dist sqrt(world-width * world-width +  world-height *  world-height )
  let distance_ sqrt ((x1 - x2) ^ 2 + (y1 - y2) ^ 2)

  set sim (sim + 1.0 - distance_ / max-dist)

  let diff_salary ([salary] of unemployee_) - ([salary] of company_)
  set sim (sim + 0.5 * (1.0 + diff_salary / max-salary))
  set sim (sim + (random-float unexpected_worker_motivation))
  report sim / ( 3 + unexpected_worker_motivation)
end

to-report compute_similarities_company [unemployee_ company_ ]

  let skills_unemployee ([skills] of unemployee_)
  let skills_company  ([skills] of company_)
  let sim 0
  foreach range (length skills_unemployee)[i ->
    if (item i skills_unemployee) = (item i skills_company)[
      set sim (sim + 1)
    ]
  ]
  set sim sim / 5

  let x1 [xcor] of unemployee_
  let y1 [ycor] of unemployee_
  let x2 [xcor] of company_
  let y2 [ycor] of company_
  let max-dist sqrt(world-width * world-width +  world-height *  world-height )
  let distance_ sqrt ((x1 - x2) ^ 2 + (y1 - y2) ^ 2)

  set sim (sim + 1.0 - distance_ / max-dist)

  let diff_salary ([salary] of company_) - ([salary] of unemployee_)
  set sim (sim + 0.5 * (1.0 + diff_salary / max-salary))
  set sim (sim + (random-float unexpected_company_motivation))
  report sim / ( 3 + unexpected_company_motivation)
end

to setup_simulation [U V]
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  ask turtles [die]
  set vacancy_rate_list []
  set unemployment_rate_list []
  set u_to_plot []
  set v_to_plot []
  if list_u = 0 [
    set list_u []
    set list_v []
  ]
  set nb_pairs_max 10
  set max-salary 100
  set convergence_treshold 0.1
  set number_of_persons U
  set number_of_companies V
  create-persons U ; create the persons, then initialize their variables
  [
    set shape  "person"
    set color red
    set size 1.5  ; easier to see
    set label-color blue - 2
    setxy random-xcor random-ycor
    set skills (list (one-of [ true false ]) (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ]))
    set salary random-float max-salary
    set employed false
  ]

  create-companies V ; create the companies, then initialize their variables
  [
    set shape "triangle"
    set color red
    set size 1  ; easier to see
    setxy random-xcor random-ycor
    set skills (list (one-of [ true false ]) (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ])  (one-of [ true false ]))
    set salary random-float max-salary
    set filled false
  ]

  create-matchings 1
  [
    set matching_id who
    set unemployed []
    set vacant []
  ]


  reset-ticks
end

to run_simulation
  let timeout 5000
  let convergence False
  ifelse length unemployment_rate_list > 20 [
    let vac_last item (length vacancy_rate_list - 1) vacancy_rate_list
    let vac_be  item (length vacancy_rate_list - 2) vacancy_rate_list
    let unemp_last item (length unemployment_rate_list - 1) unemployment_rate_list
    let unemp_be item (length unemployment_rate_list - 2) unemployment_rate_list

    set convergence (abs (vac_last - vac_be) < convergence_treshold) and (abs (unemp_last - unemp_be) < convergence_treshold)
  ][
    set convergence False
  ]
  while [ticks < timeout and not convergence] [
    ifelse show_beveridge [
      go
    ][
      stop
    ]
  ]
  set u_to_plot lput (item (length unemployment_rate_list - 1) unemployment_rate_list) u_to_plot
  set v_to_plot lput (item (length vacancy_rate_list - 1) vacancy_rate_list) v_to_plot
end



to beveridge_simulations
  foreach (List 100 200 300 400) [ [u] ->
    show u
    foreach (List 100 200 300 400) [ [v] ->
      show v
      foreach range 3 [
        ifelse show_beveridge [
          setup_simulation u v
          run_simulation
        ][
          stop
        ]
      ]
      set list_u lput (mean u_to_plot) list_u
      set list_v lput (mean v_to_plot) list_v

  ]]

end



to beveridge

  let index_max (min (List (length list_u) (length list_v)))
  foreach range index_max [ [i] ->

    let u_ item i list_u
    let v_ item i list_v
    plotxy u_ v_

  ]
end

to plot_unemployment_rate

  plot ( ( count persons with [not employed]) / number_of_persons )

end

to plot_vacancy_rate
  ifelse choose_extension = "both" or choose_extension = "multiple_jobs_per_company" [
    let count1 0
    let count2 0
    ask matching matching_id [
      foreach vacant [ x ->
        ask company x [
          foreach jobs [i ->
            set count2 count2 + 1
            if not item 0 i [
              set count1 count1 + 1
            ]
          ]
        ]
      ]
    ]
    plot (count1 / count2)
  ][
    plot  ( ( count companies with [not filled] ) / number_of_companies )
  ]

end

to plot_hiring_rate
  plot hiring_rate
end

to plot_firing_rate
  plot firing_rate
end
@#$#@#$#@
GRAPHICS-WINDOW
369
25
900
557
-1
-1
15.85
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
21
225
310
258
matching_quality_treshold
matching_quality_treshold
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
20
267
310
300
firing_quality_treshold
firing_quality_treshold
0
1
0.6
0.1
1
NIL
HORIZONTAL

SLIDER
20
308
311
341
unexpected_firing
unexpected_firing
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
21
348
311
381
max_productivity_fluctuation
max_productivity_fluctuation
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
21
391
310
424
unexpected_company_motivation
unexpected_company_motivation
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
22
432
311
465
unexpected_worker_motivation
unexpected_worker_motivation
0
1
0.8
0.1
1
NIL
HORIZONTAL

BUTTON
466
585
540
618
Setup
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
573
586
636
619
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
927
316
1510
588
Courbe de Beveridge
NIL
NIL
0.75
1.0
0.0
3.75
true
true
"" ""
PENS
"Beveridge" 1.0 2 -14730904 true "beveridge" "beveridge"

INPUTBOX
23
21
184
81
number_of_persons
100.0
1
0
Number

INPUTBOX
24
91
185
151
number_of_companies
100.0
1
0
Number

BUTTON
659
589
807
622
Beveridge Curve
beveridge_simulations
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SWITCH
469
630
641
663
show_beveridge
show_beveridge
1
1
-1000

SLIDER
21
182
309
215
exceptional_matching
exceptional_matching
0
1
0.1
0.1
1
NIL
HORIZONTAL

PLOT
927
26
1510
301
Vacancy rate, unemployment rate, firing rate et hiring rate
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"Unemployment rate" 1.0 0 -5298144 true "" "plot_unemployment_rate"
"Vacancy_rate" 1.0 0 -7500403 true "" "plot_vacancy_rate"

SLIDER
22
473
311
506
resignation_treshold
resignation_treshold
0
1
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
24
516
311
549
birth_rate
birth_rate
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
24
555
311
588
company_creation_rate
company_creation_rate
0
1
0.3
0.1
1
NIL
HORIZONTAL

CHOOSER
25
600
312
645
choose_extension
choose_extension
"none" "open_system" "multiple_jobs_per_company"
0

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
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
