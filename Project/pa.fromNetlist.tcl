
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name Project -dir "C:/Users/Ethan/Dropbox/Engs31/Project/Project/planAhead_run_3" -part xc6slx16csg324-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/Ethan/Dropbox/Engs31/Project/Project/project_top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/Ethan/Dropbox/Engs31/Project/Project} }
set_property target_constrs_file "audio_project.ucf" [current_fileset -constrset]
add_files [list {audio_project.ucf}] -fileset [get_property constrset [current_run]]
link_design
