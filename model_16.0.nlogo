extensions[
  csv
  profiler
  time
  rnd
]

globals[
  ;;;;;;;;;;;;;;;;;;;;;;input file;;;;;;;;;;;;;;;;;;;;;
  file
  file_patient_properties
  quanta_timestep
  output_timestep
  clinic
  files_scheduling
  vitals_scheduling
  cons_scheduling
  ACH_list
  room_volume_list
  prop_adult_infectious
  prop_child_infectious
  quanta_rate
  breath_rate_adult
  breath_rate_child
  intervention_reduction_files_time
  intervention_reduction_vitals_time
  intervention_reduction_cons_time
  mask_reduction_out
  mask_reduction_in
  ACH_number
  number_allowed_files_queue
  number_allowed_vitals_queue
  number_allowed_cons_queue
  UVGI_ACH
  CCMDD_prop

  ACTS_list
  UVGI_ACTS


  ;;;;;;;;;;;;;;;repeats;;;;;;;;;;;;;;;;;
  repeats
  interventions
  movement_copys
  movement_number
  run_number
  patient_number
  intervention_number
  repeat_number
  impute_number
  impute_copys


  ;;;;;;;;;;;;;;;;;;time;;;;;;;;;;;;;;;;;;;;
  current_time
  ended

  ;;;;;;;;;;;;;;;;;;tracking;;;;;;;;;;;;;;;;;;;;
  location_tracking_adult_mask_list
  location_tracking_child_mask_list
  location_tracking_adult_nomask_list
  location_tracking_child_nomask_list
  quanta_in_room_list
  risk_in_room_list

  files_scheduling_list_who
  files_scheduling_list_gap
  files_scheduling_list_input_time
  files_scheduling_list_ready
  vitals_scheduling_list_who
  vitals_scheduling_list_input_time
  vitals_scheduling_list_gap
  vitals_scheduling_list_ready
  cons_scheduling_list_who
  cons_scheduling_list_input_time
  cons_scheduling_list_gap
  cons_scheduling_list_ready
  files_on_off
  vitals_on_off
  cons_on_off
  files_first_started
  vitals_first_started
  cons_first_started
  files_currently_restarting
  vitals_currently_restarting
  cons_currently_restarting
  queue_tracking_list

  allowed_inside_files_list
  allowed_inside_vitals_list
  allowed_inside_cons_list
  number_wait_inside_files
  number_wait_inside_vitals
  number_wait_inside_cons
]


turtles-own [
  ;;input
  id
  arrive_time_data
  files_time_data
  vitals_time_data
  cons_time_data
  leave_time_data
  files_loc_input
  vitals_loc_input
  cons_loc_input
  agecat
  files_gap_to_next
  vitals_gap_to_next
  cons_gap_to_next
  gap_arrive_files
  gap_files_vitals
  gap_vitals_cons
  gap_cons_leave
  simulated_arrive
  mask
  HIV_care


  ;;other
  files_time_data_adjusted
  vitals_time_data_adjusted
  cons_time_data_adjusted
  leave_time_data_adjusted

  arrive_time_occurred
  files_entered_occurred
  files_time_occurred
  vitals_entered_occurred
  vitals_time_occurred
  cons_entered_occurred
  cons_time_occurred
  leave_time_occurred

  location
  own_quanta_in_room
  risk_current_quanta_timestep
  cummulative_risk_list

  first_at_files
  first_at_vitals
  first_at_cons
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;setup overall;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  reset-ticks
  read_in_inputs
  set run_number 0
  repeat repeats [
    repeat interventions [
      repeat impute_copys [
        repeat movement_copys [
          ask turtles [die]
          set run_number (run_number + 1)
          set intervention_number item 1 item 19 file_patient_properties
          set impute_number item 1 item 20 file_patient_properties
          set repeat_number item 1 item 0 file_patient_properties
          set movement_number item 1 item 23 file_patient_properties
          setup_run
          foreach n-values length file_patient_properties  [ i -> i ] [
            i ->
            let val_list item i file_patient_properties
            set val_list sublist val_list (patient_number) (length val_list)
            set file_patient_properties replace-item i file_patient_properties val_list
          ]
        ]
      ]
    ]
  ]
  set ended 1
end

to read_in_inputs
  set file csv:from-file (word "inputs" clinic_number "_" experiment_number ".csv")
  foreach file
    [
      ? -> run (word "set " item 0 ? " " item 1 ?)
  ]
  set file_patient_properties csv:from-file (word "patients_clinic" clinic ".csv")
  let var length item 1 file_patient_properties
  let people length file_patient_properties
  let file_patient_properties_temp []
  foreach n-values var [ v -> v ] [
    v ->
    let temp_list []
    foreach n-values people [ p -> p ] [
      p ->
      if p > 0 [
        let val item v item p file_patient_properties
        set temp_list lput val temp_list
      ]
    ]
    set file_patient_properties_temp lput temp_list file_patient_properties_temp
  ]
  set file_patient_properties file_patient_properties_temp
  set patient_number length remove-duplicates item 1 file_patient_properties
  set repeats max item 0 file_patient_properties
  set interventions length remove-duplicates item 19 file_patient_properties
  set impute_copys length remove-duplicates item 20 file_patient_properties
  set movement_copys length remove-duplicates item 23 file_patient_properties
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;setup runs;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup_run
  reset-ticks
  set current_time time:anchor-to-ticks (time:create "1960-01-01 06:30:00.000") 1 "second"
  time:anchor-schedule (time:create "1960-01-01 06:30:00.000") 1 "second"
  set files_first_started 0
  set vitals_first_started 0
  set cons_first_started 0
  set files_on_off 0
  set vitals_on_off 0
  set cons_on_off 0
  set files_currently_restarting 0
  set vitals_currently_restarting 0
  set cons_currently_restarting 0
  set location_tracking_adult_mask_list n-values 10 [0]
  set location_tracking_child_mask_list n-values 10 [0]
  set location_tracking_adult_nomask_list n-values 10 [0]
  set location_tracking_child_nomask_list n-values 10 [0]
  set queue_tracking_list n-values 5 [0]
  set queue_tracking_list replace-item 0 queue_tracking_list patient_number
  set quanta_in_room_list n-values 10 [0]
  set risk_in_room_list n-values 10 [0]
  set ACTS_list n-values 10 [0]
  set files_scheduling_list_who []
  set files_scheduling_list_gap []
  set files_scheduling_list_input_time []
  set files_scheduling_list_ready []
  set vitals_scheduling_list_who []
  set vitals_scheduling_list_gap []
  set vitals_scheduling_list_input_time []
  set vitals_scheduling_list_ready []
  set cons_scheduling_list_who []
  set cons_scheduling_list_gap []
  set cons_scheduling_list_input_time []
  set cons_scheduling_list_ready []
  setup_patients
  setup_scheduling_lists
  interventions_changing_times
  setup_initial_loc
  setup_track_quanta
  clear-output
  setup_output
  go
end

to go
  time:go-until (time:create "1960-01-01 23:59:59.001")
end


to setup_patients
  foreach n-values patient_number [ i -> i ] [
    x ->
    create-turtles 1 [
      set id item x item 1 file_patient_properties
      set arrive_time_data time:create item x item 2 file_patient_properties
      set files_time_data time:create item x item 3 file_patient_properties
      set vitals_time_data time:create item x item 4 file_patient_properties
      set cons_time_data time:create item x item 5 file_patient_properties
      set leave_time_data time:create item x item 6 file_patient_properties
      set HIV_care item x item 7 file_patient_properties
      set files_loc_input item x item 8 file_patient_properties
      set vitals_loc_input item x item 9 file_patient_properties
      set cons_loc_input item x item 10 file_patient_properties
      set agecat item x item 11 file_patient_properties
      set files_gap_to_next item x item 12 file_patient_properties
      set vitals_gap_to_next item x item 13 file_patient_properties
      set cons_gap_to_next item x item 14 file_patient_properties
      set gap_arrive_files item x item 15 file_patient_properties
      set gap_files_vitals item x item 16 file_patient_properties
      set gap_vitals_cons item x item 17 file_patient_properties
      set gap_cons_leave item x item 18 file_patient_properties
      set simulated_arrive time:create item x item 21 file_patient_properties
      set mask item x item 22 file_patient_properties

      set cummulative_risk_list n-values 10 [0]

      set arrive_time_occurred time:create "1959-01-01 00:00:00"
      set files_time_occurred time:create "1959-01-01 00:00:00"
      set vitals_time_occurred time:create "1959-01-01 00:00:00"
      set cons_time_occurred time:create "1959-01-01 00:00:00"
      set leave_time_occurred time:create "1959-01-01 00:00:00"

      set files_entered_occurred time:create "1959-01-01 00:00:00"
      set vitals_entered_occurred time:create "1959-01-01 00:00:00"
      set cons_entered_occurred time:create "1959-01-01 00:00:00"

      set files_time_data_adjusted time:plus simulated_arrive gap_arrive_files "seconds"
      set vitals_time_data_adjusted time:plus files_time_data_adjusted gap_files_vitals "seconds"
      set cons_time_data_adjusted time:plus vitals_time_data_adjusted gap_vitals_cons "seconds"
      set leave_time_data_adjusted time:plus cons_time_data_adjusted gap_cons_leave "seconds"
    ]
  ]

  ask turtles [
      if HIV_care < CCMDD_prop [
        die
      ]
  ]

  ask min-one-of turtles [time:difference-between time:create "1959-01-01 00:00:00" files_time_data_adjusted "seconds"]
  [set first_at_files 1]
  ask min-one-of turtles [time:difference-between time:create "1959-01-01 00:00:00" vitals_time_data_adjusted "seconds"]
  [set first_at_vitals 1]
  ask min-one-of turtles [time:difference-between time:create "1959-01-01 00:00:00" cons_time_data_adjusted "seconds"]
  [set first_at_cons 1]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;movement;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup_scheduling_lists
  foreach sort-on [time:difference-between time:create "1959-01-01 00:00:00" files_time_data_adjusted "seconds"] turtles
  [the-turtle -> ask the-turtle [
    set files_scheduling_list_who lput who files_scheduling_list_who
    set files_scheduling_list_input_time lput files_time_data_adjusted files_scheduling_list_input_time
    set files_scheduling_list_ready lput 0 files_scheduling_list_ready
    set files_scheduling_list_gap lput files_gap_to_next files_scheduling_list_gap
    ]
  ]

  foreach sort-on [time:difference-between time:create "1959-01-01 00:00:00" vitals_time_data_adjusted "seconds"] turtles
  [the-turtle -> ask the-turtle [
    set vitals_scheduling_list_who lput who vitals_scheduling_list_who
    set vitals_scheduling_list_input_time lput vitals_time_data_adjusted vitals_scheduling_list_input_time
    set vitals_scheduling_list_ready lput 0 vitals_scheduling_list_ready
    set vitals_scheduling_list_gap lput vitals_gap_to_next vitals_scheduling_list_gap
    ]
  ]
  foreach sort-on [time:difference-between time:create "1959-01-01 00:00:00" cons_time_data_adjusted "seconds"] turtles
  [the-turtle -> ask the-turtle [
    set cons_scheduling_list_who lput who cons_scheduling_list_who
    set cons_scheduling_list_input_time lput cons_time_data_adjusted cons_scheduling_list_input_time
    set cons_scheduling_list_ready lput 0 cons_scheduling_list_ready
    set cons_scheduling_list_gap lput cons_gap_to_next cons_scheduling_list_gap
    ]
  ]

  set allowed_inside_files_list files_scheduling_list_who
  set allowed_inside_vitals_list vitals_scheduling_list_who
  set allowed_inside_cons_list cons_scheduling_list_who
end

to setup_initial_loc
  ask turtles [
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item 0 location_tracking_child_nomask_list (item 0 location_tracking_child_nomask_list + 1)]
      [set location_tracking_adult_nomask_list replace-item 0 location_tracking_adult_nomask_list (item 0 location_tracking_adult_nomask_list + 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item 0 location_tracking_child_mask_list (item 0 location_tracking_child_mask_list + 1)]
      [set location_tracking_adult_mask_list replace-item 0 location_tracking_adult_mask_list (item 0 location_tracking_adult_mask_list + 1)]
    ]
    setup_arrival
  ]
end

to setup_arrival
  time:schedule-event self [ [] ->
    reach_arrive
  ] (simulated_arrive)
end

to reach_arrive
  if location != 9 [
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list - 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list - 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list - 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list - 1)]
    ]
    set location 9
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list + 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list + 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list + 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list + 1)]
    ]
    set own_quanta_in_room 0
  ]

  if position who allowed_inside_files_list < (number_allowed_files_queue - number_wait_inside_files)
  [
    enter_clinic_files
  ]


  set arrive_time_occurred time:copy current_time
  set queue_tracking_list replace-item 0 queue_tracking_list (item 0 queue_tracking_list - 1)
  set queue_tracking_list replace-item 1 queue_tracking_list (item 1 queue_tracking_list + 1)

  if files_scheduling = 0
  [
    setup_files_absolute
  ]
  if files_scheduling = 1
  [
    let i position who files_scheduling_list_who
    set files_scheduling_list_ready replace-item i files_scheduling_list_ready 1
    if (files_on_off = 0 and first_at_files = 1) or (files_on_off = 0 and files_first_started = 1 and files_currently_restarting = 0) [restart_files_relative]
    ;if (files_on_off = 0 and files_currently_restarting = 0) [restart_files_relative]
  ]
  if files_scheduling = 2
  [
    schedule_files_gap
  ]
end

to enter_clinic_files
  set number_wait_inside_files (number_wait_inside_files + 1)
  let pos position who allowed_inside_files_list
  set allowed_inside_files_list remove-item pos allowed_inside_files_list
  if location != files_loc_input [
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list - 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list - 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list - 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list - 1)]
    ]
    set location files_loc_input
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list + 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list + 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list + 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list + 1)]
    ]
    set own_quanta_in_room 0
  ]

  set files_entered_occurred time:copy current_time
end


to reach_files
  ifelse time:is-equal files_entered_occurred time:create "1959-01-01 00:00:00"
  [
    set files_entered_occurred time:copy current_time
    let pos position who allowed_inside_files_list
    set allowed_inside_files_list remove-item pos allowed_inside_files_list
  ]
  [set number_wait_inside_files (number_wait_inside_files - 1)
    call_next_inside_files]
  if location != 9 [
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list - 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list - 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list - 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list - 1)]
    ]
    set location 9
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list + 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list + 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list + 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list + 1)]
    ]
    set own_quanta_in_room 0
  ]

  if position who allowed_inside_vitals_list < (number_allowed_vitals_queue - number_wait_inside_vitals)
  [
    enter_clinic_vitals
  ]


  set files_time_occurred time:copy current_time
  set queue_tracking_list replace-item 1 queue_tracking_list (item 1 queue_tracking_list - 1)
  set queue_tracking_list replace-item 2 queue_tracking_list (item 2 queue_tracking_list + 1)

  if files_scheduling = 1
  [schedule_next_files_relative]
  if vitals_scheduling = 0
  [
    setup_vitals_absolute
  ]
  if vitals_scheduling = 1
  [
    let i position who vitals_scheduling_list_who
    set vitals_scheduling_list_ready replace-item i vitals_scheduling_list_ready 1
    if (vitals_on_off = 0 and first_at_vitals = 1) or (vitals_on_off = 0 and vitals_first_started = 1 and vitals_currently_restarting = 0) [restart_vitals_relative]
  ]
  if vitals_scheduling = 2
  [
    schedule_vitals_gap
  ]
end

to call_next_inside_files
  let someone_entered 0
  foreach n-values number_allowed_files_queue [ j -> j ] [
    [i] ->
    if someone_entered = 0 and length allowed_inside_files_list > i [
      ask turtle item i allowed_inside_files_list
      [
        ifelse time:is-equal arrive_time_occurred time:create "1959-01-01 00:00:00"
        []
        [set someone_entered 1
          enter_clinic_files]
      ]
    ]
  ]
end

to enter_clinic_vitals
  set number_wait_inside_vitals (number_wait_inside_vitals + 1)
  let pos position who allowed_inside_vitals_list
  set allowed_inside_vitals_list remove-item pos allowed_inside_vitals_list
  if location != vitals_loc_input [
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list - 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list - 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list - 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list - 1)]
    ]
    set location vitals_loc_input
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list + 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list + 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list + 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list + 1)]
    ]
    set own_quanta_in_room 0
  ]

  set vitals_entered_occurred time:copy current_time
end

to reach_vitals
  ifelse time:is-equal vitals_entered_occurred time:create "1959-01-01 00:00:00"
  [
    set vitals_entered_occurred time:copy current_time
    let pos position who allowed_inside_vitals_list
    set allowed_inside_vitals_list remove-item pos allowed_inside_vitals_list
  ]
  [set number_wait_inside_vitals (number_wait_inside_vitals - 1)
    call_next_inside_vitals]
  if location != 9 [
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list - 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list - 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list - 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list - 1)]
    ]
    set location 9
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list + 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list + 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list + 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list + 1)]
    ]
    set own_quanta_in_room 0
  ]

  if (position who allowed_inside_cons_list) < (number_allowed_cons_queue - number_wait_inside_cons)
  [
    enter_clinic_cons
  ]

  set vitals_time_occurred time:copy current_time
  set queue_tracking_list replace-item 2 queue_tracking_list (item 2 queue_tracking_list - 1)
  set queue_tracking_list replace-item 3 queue_tracking_list (item 3 queue_tracking_list + 1)

  if vitals_scheduling = 1
  [schedule_next_vitals_relative]
  if cons_scheduling = 0
  [
    setup_cons_absolute
  ]
  if cons_scheduling = 1
  [
    let i position who cons_scheduling_list_who
    set cons_scheduling_list_ready replace-item i cons_scheduling_list_ready 1
    if (cons_on_off = 0 and first_at_cons = 1) or (cons_on_off = 0 and cons_first_started = 1 and cons_currently_restarting = 0) [restart_cons_relative]
  ]
  if cons_scheduling = 2
  [
    schedule_cons_gap
  ]
end

to call_next_inside_vitals
  let someone_entered 0
  foreach n-values number_allowed_vitals_queue [ j -> j ] [
    [i] ->
    if someone_entered = 0 and length allowed_inside_vitals_list > i [
      ask turtle item i allowed_inside_vitals_list
      [
        ifelse time:is-equal files_time_occurred time:create "1959-01-01 00:00:00"
        []
        [set someone_entered 1
          enter_clinic_vitals]
      ]
    ]
  ]
end

to enter_clinic_cons
  set number_wait_inside_cons (number_wait_inside_cons + 1)
  let pos position who allowed_inside_cons_list
  set allowed_inside_cons_list remove-item pos allowed_inside_cons_list
  if location != cons_loc_input [
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list - 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list - 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list - 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list - 1)]
    ]
    set location cons_loc_input
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list + 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list + 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list + 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list + 1)]
    ]
    set own_quanta_in_room 0
  ]

  set cons_entered_occurred time:copy current_time
end

to reach_cons
  ifelse time:is-equal cons_entered_occurred time:create "1959-01-01 00:00:00"
  [
    set cons_entered_occurred time:copy current_time
    let pos position who allowed_inside_cons_list
    set allowed_inside_cons_list remove-item pos allowed_inside_cons_list
  ]
  [set number_wait_inside_cons (number_wait_inside_cons - 1)
    call_next_inside_cons]
  if location != 0 [
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list - 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list - 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list - 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list - 1)]
    ]
    set location 0
    ifelse mask = 0
    [
      ifelse agecat = 0
              [set location_tracking_child_nomask_list replace-item location location_tracking_child_nomask_list (item location location_tracking_child_nomask_list + 1)]
      [set location_tracking_adult_nomask_list replace-item location location_tracking_adult_nomask_list (item location location_tracking_adult_nomask_list + 1)]
    ]
    [
      ifelse agecat = 0
              [set location_tracking_child_mask_list replace-item location location_tracking_child_mask_list (item location location_tracking_child_mask_list + 1)]
      [set location_tracking_adult_mask_list replace-item location location_tracking_adult_mask_list (item location location_tracking_adult_mask_list + 1)]
    ]
    set own_quanta_in_room 0
  ]
  set cons_time_occurred time:copy current_time
  set queue_tracking_list replace-item 3 queue_tracking_list (item 3 queue_tracking_list - 1)
  set queue_tracking_list replace-item 4 queue_tracking_list (item 4 queue_tracking_list + 1)

  if cons_scheduling = 1
  [schedule_next_cons_relative]

  set leave_time_occurred time:plus cons_time_occurred gap_cons_leave "seconds"
end

to call_next_inside_cons
  let someone_entered 0
  foreach n-values number_allowed_cons_queue [ j -> j ] [
    [i] ->
    if someone_entered = 0 and length allowed_inside_cons_list > i [
      ask turtle item i allowed_inside_cons_list
      [
        ifelse time:is-equal vitals_time_occurred time:create "1959-01-01 00:00:00"
        []
        [set someone_entered 1
          enter_clinic_cons]
      ]
    ]
  ]
end

to schedule_files_gap
  time:schedule-event self [ [] ->
    reach_files
  ] ticks + gap_arrive_files
end

to schedule_vitals_gap
  time:schedule-event self [ [] ->
    reach_vitals
  ] ticks + gap_files_vitals
end

to schedule_cons_gap
  time:schedule-event self [ [] ->
    reach_cons
  ] ticks + gap_vitals_cons
end


to setup_files_absolute
  ifelse time:is-before files_time_data_adjusted current_time
  [reach_files]
  [
    time:schedule-event self [ [] ->
      reach_files
    ] (files_time_data_adjusted)
  ]
end

to setup_vitals_absolute
  ifelse time:is-before vitals_time_data_adjusted current_time
  [reach_vitals]
  [
    time:schedule-event self [ [] ->
      reach_vitals
    ] (vitals_time_data_adjusted)
  ]
end

to setup_cons_absolute
  ifelse time:is-before cons_time_data_adjusted current_time
  [reach_cons]
  [
    time:schedule-event self [ [] ->
      reach_cons
    ] (cons_time_data_adjusted)
  ]
end

to restart_files_relative
  ifelse files_first_started = 1
  [
    set files_on_off 1
    reach_files
  ]
  [
    ifelse time:is-after files_time_data_adjusted current_time
    [
      set files_currently_restarting 1
      set files_on_off 1
      set files_first_started 1
      time:schedule-event self [ [] ->
        set files_currently_restarting 0
        restart_files_relative
      ] (files_time_data_adjusted)
    ]
    [
      set files_first_started 1
      set files_on_off 1
      reach_files
    ]
  ]
end

to restart_vitals_relative
  ifelse vitals_first_started = 1
  [
    set vitals_on_off 1
    reach_vitals
  ]
  [
    ifelse time:is-after vitals_time_data_adjusted current_time
    [
      set vitals_on_off 1
      set vitals_first_started 1
      time:schedule-event self [ [] ->
        restart_vitals_relative
      ] (vitals_time_data_adjusted)
    ]
    [
      set vitals_first_started 1
      set vitals_on_off 1
      reach_vitals
    ]
  ]
end

to restart_cons_relative
  ifelse cons_first_started = 1
  [
    set cons_on_off 1
    reach_cons
  ]
  [
    ifelse time:is-after cons_time_data_adjusted current_time
    [
      set cons_on_off 1
      set cons_first_started 1
      time:schedule-event self [ [] ->
        restart_cons_relative
      ] (cons_time_data_adjusted)
    ]
    [
      set cons_first_started 1
      set cons_on_off 1
      reach_cons
    ]
  ]
end

to schedule_next_files_relative
  let i position who files_scheduling_list_who
  if length files_scheduling_list_ready > 1
  [
    time:schedule-event "observer" [ [] ->
      next_files_relative
    ] ticks + item i files_scheduling_list_gap
    set files_scheduling_list_ready remove-item i files_scheduling_list_ready
    set files_scheduling_list_who remove-item i files_scheduling_list_who
    set files_scheduling_list_input_time remove-item i files_scheduling_list_input_time
    set files_scheduling_list_gap remove-item i files_scheduling_list_gap
  ]
end

to schedule_next_vitals_relative
  let i position who vitals_scheduling_list_who
  if length vitals_scheduling_list_ready > 1
  [
    time:schedule-event "observer" [ [] ->
      next_vitals_relative
    ] ticks + item i vitals_scheduling_list_gap
    set vitals_scheduling_list_ready remove-item i vitals_scheduling_list_ready
    set vitals_scheduling_list_who remove-item i vitals_scheduling_list_who
    set vitals_scheduling_list_input_time remove-item i vitals_scheduling_list_input_time
    set vitals_scheduling_list_gap remove-item i vitals_scheduling_list_gap
  ]
end

to schedule_next_cons_relative
  let i position who cons_scheduling_list_who
  if length cons_scheduling_list_ready > 1
  [
    time:schedule-event "observer" [ [] ->
      next_cons_relative
    ] ticks + item i cons_scheduling_list_gap
    set cons_scheduling_list_ready remove-item i cons_scheduling_list_ready
    set cons_scheduling_list_who remove-item i cons_scheduling_list_who
    set cons_scheduling_list_input_time remove-item i cons_scheduling_list_input_time
    set cons_scheduling_list_gap remove-item i cons_scheduling_list_gap
  ]
end

to next_files_relative
  let i position 1 files_scheduling_list_ready
  ifelse i = false
  [set files_on_off 0]
  [ask turtle item i files_scheduling_list_who
    [
      reach_files
    ]
  ]
end

to next_vitals_relative
  let i position 1 vitals_scheduling_list_ready
  ifelse i = false
  [set vitals_on_off 0]
  [ask turtle item i vitals_scheduling_list_who
    [
      reach_vitals
    ]
  ]
end

to next_cons_relative
  let i position 1 cons_scheduling_list_ready
  ifelse i = false
  [set cons_on_off 0]
  [ask turtle item i cons_scheduling_list_who
    [
      reach_cons
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;interventions;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to interventions_changing_times
  foreach n-values (length files_scheduling_list_gap) [ n -> n ] [
    [i] ->
    set files_scheduling_list_gap replace-item i files_scheduling_list_gap ((item i files_scheduling_list_gap) * intervention_reduction_files_time)
  ]

  foreach n-values (length vitals_scheduling_list_gap) [ n -> n ] [
    [i] ->
    set vitals_scheduling_list_gap replace-item i vitals_scheduling_list_gap ((item i vitals_scheduling_list_gap) * intervention_reduction_vitals_time)
  ]

  foreach n-values (length cons_scheduling_list_gap) [ n -> n ] [
    [i] ->
    set cons_scheduling_list_gap replace-item i cons_scheduling_list_gap ((item i cons_scheduling_list_gap) * intervention_reduction_cons_time)
  ]
end





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;quanta;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup_track_quanta
  foreach n-values 10 [ i -> i ] [
    [i] ->
    set ACTS_list replace-item i ACTS_list (1 - EXP(- (quanta_timestep / 60 / 60) * item i ACH_list))
  ]
  set UVGI_ACTS (1 - EXP(- (quanta_timestep / 60 / 60) * UVGI_ACH))
  time:schedule-repeating-event "observer" [ [] ->
    individuals_quanta_in_room
    total_quanta_in_room
    individuals_risk
    update_risk_in_room_list
  ]
  0 quanta_timestep
end

to individuals_quanta_in_room
  ask turtles [
    ifelse mask = 0
    [
      ifelse agecat = 0
      [set own_quanta_in_room (own_quanta_in_room * (exp(- item location ACTS_list - UVGI_ACTS)) + prop_child_infectious * quanta_rate * (quanta_timestep / 60 / 60))]
      [set own_quanta_in_room (own_quanta_in_room * (exp(- item location ACTS_list - UVGI_ACTS)) + prop_adult_infectious * quanta_rate * (quanta_timestep / 60 / 60))]
    ]
    [
      ifelse agecat = 0
      [set own_quanta_in_room (own_quanta_in_room * (exp(- item location ACTS_list - UVGI_ACTS)) + prop_child_infectious * quanta_rate * mask_reduction_out * (quanta_timestep / 60 / 60))]
      [set own_quanta_in_room (own_quanta_in_room * (exp(- item location ACTS_list - UVGI_ACTS)) + prop_adult_infectious * quanta_rate * mask_reduction_out * (quanta_timestep / 60 / 60))]
    ]
  ]
end

to total_quanta_in_room
  foreach n-values 10 [ i -> i ] [
    [i] ->
    set quanta_in_room_list replace-item i quanta_in_room_list
    (item i quanta_in_room_list * exp(- item i ACTS_list - UVGI_ACTS)  ;ventilation
      + item i location_tracking_adult_nomask_list * prop_adult_infectious * quanta_rate * (quanta_timestep / 60 / 60)  ;add new from adults
      + item i location_tracking_child_nomask_list * prop_child_infectious * quanta_rate * (quanta_timestep / 60 / 60)  ;add new from children
      + item i location_tracking_adult_mask_list * prop_adult_infectious * quanta_rate * mask_reduction_out * (quanta_timestep / 60 / 60)  ;add new from adults
      + item i location_tracking_child_mask_list * prop_child_infectious * quanta_rate * mask_reduction_out * (quanta_timestep / 60 / 60)  ;add new from children
    )
  ]
end

to individuals_risk
  ask turtles [
    ifelse mask = 0
    [
      ifelse agecat = 0
      [set risk_current_quanta_timestep (1 - EXP(- (item location quanta_in_room_list - own_quanta_in_room) * breath_rate_child * (quanta_timestep / 60 / 60) / (item location room_volume_list)))]
      [set risk_current_quanta_timestep (1 - EXP(- (item location quanta_in_room_list - own_quanta_in_room) * breath_rate_adult * (quanta_timestep / 60 / 60) / (item location room_volume_list)))]
      set cummulative_risk_list replace-item location cummulative_risk_list (item location cummulative_risk_list + risk_current_quanta_timestep)
    ]
    [
      ifelse agecat = 0
      [set risk_current_quanta_timestep (1 - EXP(- (item location quanta_in_room_list - own_quanta_in_room) * breath_rate_child * mask_reduction_in * (quanta_timestep / 60 / 60) / (item location room_volume_list)))]
      [set risk_current_quanta_timestep (1 - EXP(- (item location quanta_in_room_list - own_quanta_in_room) * breath_rate_adult * mask_reduction_in * (quanta_timestep / 60 / 60) / (item location room_volume_list)))]
      set cummulative_risk_list replace-item location cummulative_risk_list (item location cummulative_risk_list + risk_current_quanta_timestep)
    ]
  ]
end

to update_risk_in_room_list
  ask turtles [
    set risk_in_room_list replace-item location risk_in_room_list (item location risk_in_room_list + risk_current_quanta_timestep)
  ]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;output;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup_output
  output_column_names
  time:schedule-repeating-event "observer" [ [] ->
    print_output
  ]
  0 output_timestep

  time:schedule-event "observer" [ [] ->
    export-model-output
    clear-output
  ]
  time:create "1960-01-01 23:59:59.000"
end

to output_column_names
  output-type (word "time" ",")
  output-type (word "risk_loc1" ",")
  output-type (word "risk_loc2" ",")
  output-type (word "risk_loc3" ",")
  output-type (word "risk_loc4" ",")
  output-type (word "risk_loc5" ",")
  output-type (word "risk_loc6" ",")
  output-type (word "risk_loc7" ",")
  output-type (word "risk_loc8" ",")
  output-type (word "risk_loc9" ",")
  ifelse ACH_number = 1 [
    output-type (word "people_queuing_loc1" ",")
    output-type (word "people_queuing_loc2" ",")
    output-type (word "people_queuing_loc3" ",")
    output-type (word "people_queuing_loc4" ",")
    output-type (word "people_queuing_loc5" ",")
    output-type (word "people_queuing_loc6" ",")
    output-type (word "people_queuing_loc7" ",")
    output-type (word "people_queuing_loc8" ",")
    output-type (word "people_queuing_loc9" ",")
    output-type (word "queue1" ",")
    output-type (word "queue2" ",")
    output-type (word "queue3" ",")
    output-print (word "queue4" ",")
  ]
  [output-print (word ",")]
end

to print_output
  output-type (word time:show current_time "HH:mm:ss" ",")
  output-type (word item 1 risk_in_room_list ",")
  output-type (word item 2 risk_in_room_list ",")
  output-type (word item 3 risk_in_room_list ",")
  output-type (word item 4 risk_in_room_list ",")
  output-type (word item 5 risk_in_room_list ",")
  output-type (word item 6 risk_in_room_list ",")
  output-type (word item 7 risk_in_room_list ",")
  output-type (word item 8 risk_in_room_list ",")
  output-type (word item 9 risk_in_room_list ",")
  ifelse ACH_number = 1 [
    output-type (word (item 1 location_tracking_child_nomask_list + item 1 location_tracking_child_mask_list + item 1 location_tracking_adult_nomask_list + item 1 location_tracking_adult_mask_list) ",")
    output-type (word (item 2 location_tracking_child_nomask_list + item 2 location_tracking_child_mask_list + item 2 location_tracking_adult_nomask_list + item 2 location_tracking_adult_mask_list) ",")
    output-type (word (item 3 location_tracking_child_nomask_list + item 3 location_tracking_child_mask_list + item 3 location_tracking_adult_nomask_list + item 3 location_tracking_adult_mask_list) ",")
    output-type (word (item 4 location_tracking_child_nomask_list + item 4 location_tracking_child_mask_list + item 4 location_tracking_adult_nomask_list + item 4 location_tracking_adult_mask_list) ",")
    output-type (word (item 5 location_tracking_child_nomask_list + item 5 location_tracking_child_mask_list + item 5 location_tracking_adult_nomask_list + item 5 location_tracking_adult_mask_list) ",")
    output-type (word (item 6 location_tracking_child_nomask_list + item 6 location_tracking_child_mask_list + item 6 location_tracking_adult_nomask_list + item 6 location_tracking_adult_mask_list) ",")
    output-type (word (item 7 location_tracking_child_nomask_list + item 7 location_tracking_child_mask_list + item 7 location_tracking_adult_nomask_list + item 7 location_tracking_adult_mask_list) ",")
    output-type (word (item 8 location_tracking_child_nomask_list + item 8 location_tracking_child_mask_list + item 8 location_tracking_adult_nomask_list + item 8 location_tracking_adult_mask_list) ",")
    output-type (word (item 9 location_tracking_child_nomask_list + item 9 location_tracking_child_mask_list + item 9 location_tracking_adult_nomask_list + item 9 location_tracking_adult_mask_list) ",")
    output-type (word item 0 queue_tracking_list ",")
    output-type (word item 1 queue_tracking_list ",")
    output-type (word item 2 queue_tracking_list ",")
    output-print (word item 3 queue_tracking_list ",")
  ]
  [output-print (word ",")]
  set risk_in_room_list n-values 10 [0]
end

to export-model-output
  export-output (word "/home/eidenmcc/NetLogo-6.0.1/app/queues16_100/Time_clinic" clinic "_int" intervention_number "_imp" repeat_number "_move" movement_number "_copy" impute_number "_exp" experiment_number ".csv")
  clear-output
  if ACH_number = 1 [
    setup_output_people
    print_output_people
    export-output (word "/home/eidenmcc/NetLogo-6.0.1/app/queues16_100/Patients_clinic" clinic "_int" intervention_number "_imp" repeat_number "_move" movement_number "_copy" impute_number "_exp" experiment_number ".csv")
    clear-output
  ]
end

to setup_output_people
  output-type (word "id" ",")
  output-type (word "arrive_time_occurred" ",")
  output-type (word "files_entered_occurred" ",")
  output-type (word "files_time_occurred" ",")
  output-type (word "vitals_entered_occurred" ",")
  output-type (word "vitals_time_occurred" ",")
  output-type (word "cons_entered_occurred" ",")
  output-type (word "cons_time_occurred" ",")
  output-print (word "leave_time_occurred" ",")
end



to print_output_people
  foreach sort turtles [ the-turtle ->
    ask the-turtle [
      output-type (word id ",")
      output-type (word time:show arrive_time_occurred "HH:mm:ss" ",")
      output-type (word time:show files_entered_occurred "HH:mm:ss" ",")
      output-type (word time:show files_time_occurred "HH:mm:ss" ",")
      output-type (word time:show vitals_entered_occurred "HH:mm:ss" ",")
      output-type (word time:show vitals_time_occurred "HH:mm:ss" ",")
      output-type (word time:show cons_entered_occurred "HH:mm:ss" ",")
      output-type (word time:show cons_time_occurred "HH:mm:ss" ",")
      output-print (word time:show leave_time_occurred "HH:mm:ss" ",")
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
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

BUTTON
37
56
100
89
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

INPUTBOX
57
134
212
194
clinic_number
1.0
1
0
Number

OUTPUT
762
112
1002
166
11

INPUTBOX
62
210
217
270
experiment_number
1.0
1
0
Number

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
NetLogo 6.0.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <exitCondition>ended = 1</exitCondition>
    <enumeratedValueSet variable="clinic_number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experiment_number">
      <value value="1"/>
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
