function modpath()
  path_to_this_script = mfilename('fullpath') ;
  path_to_this_folder = fileparts(path_to_this_script) ;
  
  fda_folder_path = fullfile(path_to_this_folder, 'FlyDiscoAnalysis') ;
  fda_modpath_script_path = fullfile(fda_folder_path, 'modpath.m') ; 
  run(fda_modpath_script_path) ;  
  
  % Finally, add this folder itself, so we don't have to stay in this folder
  addpath(path_to_this_folder) ;  
end
