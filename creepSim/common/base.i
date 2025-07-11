RVE_length =  193.239 # the am mesh is slightly shorter in z direction 
tramp = 1


[Mesh]
  [base]
    type = FileMeshGenerator
  []
  [rename]
    type = RenameBoundaryGenerator
    input = base
    old_boundary = '1 2 3 4 5 6' 
    new_boundary = 'x0 x1 y0 y1 z0 z1'
  []
  [breakmesh]
    input = rename
    type = BreakMeshByBlockGenerator
  []
  use_displaced_mesh = false
[]


[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[AuxVariables]
  [D]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxKernels]
  [D]
    type = MaterialRealAux
    boundary = 'interface'
    property = damage
    execute_on = 'TIMESTEP_END'
    variable = D
    check_boundary_restricted = false #this is important
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = FINITE
        new_system = true
        formulation = TOTAL
        add_variables = true
        volumetric_locking_correction = true
        generate_output = 'cauchy_stress_xx cauchy_stress_yy cauchy_stress_zz cauchy_stress_yz cauchy_stress_xz cauchy_stress_xy '
                          'mechanical_strain_xx mechanical_strain_yy mechanical_strain_zz mechanical_strain_yz mechanical_strain_xz mechanical_strain_xy'
      []
    []
  []
[]
[Physics/SolidMechanics/CohesiveZone]
  [./czm_ik1]
    boundary = 'interface'
    strain = FINITE # use finite strins, total lagrangian formulation
    generate_output='traction_x traction_y traction_z jump_x jump_y jump_z normal_traction tangent_traction normal_jump tangent_jump' #output traction and jump
  [../]
[]

[UserObjects]
  [./euler_angle_file]
    type = PropertyReadFile
    nprop = 3
    read_type = block
    nblock = 9381
    use_zero_based_block_indexing = false
  [../]
[]

[Materials]
  [stress]
  # define the bulk material model, euler angles for each grain come from the `euler_angle_file` UserObjects
    type = NEMLCrystalPlasticity
    model = "cpdeformation"
    large_kinematics = true
    euler_angle_reader = euler_angle_file
    angle_convention = bunge
  []

  [GB]
    type = GrainBoundaryCavitation
    a0 = a0
    b0 = b0
    psi = 70
    n = 5
    P = 69444.439 # (E_penalty_minus_thickenss - 1)/(w^2)
    gamma = 2
    eps = 1e-6
    fixed_triaxiality = LOW
    growth_due_to_diffusion = true
    growth_due_to_creep = true
    boundary = 'interface'
  []  
[]


[BCs]
  [x0]
    type = DirichletBC
    variable = disp_x
    boundary = x0
    value = 0.0
  []
  [y0]
    type = DirichletBC
    variable = disp_y
    boundary = y0
    value = 0.0
  []
  [z0]
    type = DirichletBC
    variable = disp_z
    boundary = z0
    value = 0.0
  []
  [z1]
    type = FunctionNeumannBC
    boundary = z1
    function = applied_load
    variable = disp_z
  []
[]

[Functions]
  [applied_load]
 type = PiecewiseLinear
    x = '0 ${tramp} 1e7'
    y = '0 ${load} ${load}' 
  []
[]

[Constraints]
  [x1]
    type = EqualValueBoundaryConstraint
    variable = disp_x
    secondary = 'x1'
    penalty = 1e7
  []
  [y1]
    type = EqualValueBoundaryConstraint
    variable = disp_y
    secondary = 'y1'
    penalty = 1e7
  []
  [z1]
    type = EqualValueBoundaryConstraint
    variable = disp_z
    secondary = 'z1'
    penalty = 1e7
  []
[]

[Preconditioning]
  [./SMP]
    type = SMP
    full = true
  [../]
[]

[Postprocessors]
  [a]
    type = SideAverageMaterialProperty
    boundary = 'interface'
    property = average_cavity_radius
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [b]
    type = SideAverageMaterialProperty
    boundary = 'interface'
    property = average_cavity_half_spacing
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [D_max]
    type = SideExtremeMaterialProperty
    boundary = 'interface'
    mat_prop = damage
    value_type = max
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [avg_disp_z]
    type = SideAverageValue
    variable = disp_z
    boundary = z1
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
  [strain]
    type = ParsedPostprocessor
    pp_names = 'avg_disp_z'
    function = 'avg_disp_z / ${RVE_length}'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [delta_strain]
    type = ChangeOverTimePostprocessor
    postprocessor = strain
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
  [dt]
    type = TimestepSize
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
  [strain_rate]
    type = ParsedPostprocessor
    pp_names = 'delta_strain dt'
    function = 'delta_strain / dt'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [minimum_strain_rate]
    type = TimeExtremeValue
    postprocessor = strain_rate
    value_type = min
    execute_on = 'INITIAL TIMESTEP_END'
    outputs = none
  []
[]

[UserObjects]
  [kill]
    type = Terminator
    expression = 'strain_rate > 1.1*minimum_strain_rate'
    message = 'Tertiary creep has begun.'
  []
[]

[Executioner]
  type = Transient

  solve_type = 'newton'

  petsc_options = '-snes_converged_reason -ksp_converged_reason'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold -pc_hypre_boomeramg_interp_type -pc_hypre_boomeramg_coarsen_type -pc_hypre_boomeramg_agg_nl -pc_hypre_boomeramg_agg_num_paths -pc_hypre_boomeramg_truncfactor'
  petsc_options_value = 'hypre boomeramg 301 0.7 ext+i HMIS 4 2 0.4'
  

  line_search = none
  automatic_scaling = true
  l_max_its = 300
  # l_tol = 1e-7
  nl_max_its = 15
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-6
  nl_forced_its = 1
  n_max_nonlinear_pingpong = 1
  dtmin = 1e-8 #${dtmin}
  dtmax = 1e4 #${dtmax}
  end_time = 1e6
  
  [./Predictor]
    type = SimplePredictor
    scale = 1.0
    skip_after_failed_timestep = true
  [../]
  
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 1
    growth_factor = 2
    cutback_factor = 0.5
    cutback_factor_at_failure = 0.1
    optimal_iterations = 8
    iteration_window = 1
    linear_iteration_ratio = 1000000000
  []
[]

[Outputs]
  print_linear_residuals = false
  [out]
    type = CSV
  []
[]


