role :web, "xxx.xxx.xxx.xxx"


set :branch, "master"

set :deploy_to,            "/var/www/application"
set :copy_remote_dir,      "#{deploy_to}/#{temp_dir}"
set :current_docroot_dir,  "#{deploy_to}/#{current_dir}"
set :resources_dir,        "/var/www/application/resources"


set :opcache_site_address,      "preprod.example.com"
#set :opcache_utility_user,     ""
#set :opcache_utility_password, ""
set :opcache_path,              "#{deploy_to}/#{current_dir}"



set :symlink_additional_resources, [ { "#{resources_dir}/#{drupal_folder_public}" => "#{release_path}/sites/default/files" },
                                     { "#{resources_dir}/#{drupal_file_settings}" => "#{release_path}/sites/default/settings.php"},
                                   ]


set :db_name,         ""
set :db_user,         ""
set :db_password,     ""
set :db_host_master,  ""
set :db_host_slave,   ""
set :database_backup_slave, "no"
