function modpath()
  path_to_this_script = mfilename('fullpath') ;
  path_to_this_folder = fileparts(path_to_this_script) ;

  % Add path to utility functions
  utilities_folder_path = fullfile(path_to_this_folder, 'utilities') ;
  addpath(utilities_folder_path) ;
  
  % Finally, add this folder itself, so we don't have to stay in this folder
  addpath(path_to_this_folder) ;  
end
