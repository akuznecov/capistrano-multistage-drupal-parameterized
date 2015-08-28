# avoid next names for stages: "stage", "test"
# it could conflict with Ruby and Capistrano method names

set :stages, %w[prod preprod]
require 'capistrano/ext/multistage'

set :application, ""

set :copy_exclude, [".git",
                    ".gitignore",
                    "CHANGELOG.txt",
                    "COPYRIGHT.txt",
                    "INSTALL.mysql.txt",
                    "INSTALL.pgsql.txt",
                    "INSTALL.sqlite.txt",
                    "INSTALL.txt",
                    "LICENSE.txt",
                    "MAINTAINERS.txt",
                    "README.txt",
                    "UPGRADE.txt",
                    "web.config",
                  ]

set :current_dir, "current"

set :repository, ""

set :deploy_via,            :copy
set :git_enable_submodules, false
set :keep_releases,         "10"
set :scm,                   "git"
set :scm_password,          "none"
set :scm_username,          "git"
set :synchronous_connect,   true

set :copy_dir,    "copy_tmp_dir"
set :copy_cache,  "copy_cache/#{application}"
set :temp_dir,    "tmp"
set :temp_folder, "/tmp"

set :drupal_file_settings,  "settings.php"
set :drupal_folder_private, "private"
set :drupal_folder_public,  "files"

set :drush_path, "/usr/bin/drush"

set :varnishadm_path,    "/usr/bin/varnishadm"
set :varnishadm_options, "-T 127.0.0.1:6082"
set :varnishadm_pattern, "req.url ~ /"

set :opcache_opcoder,         "opcache"
set :opcache_proto,           "http"
set :opcache_proto_www,       "#{opcache_proto}"
set :opcache_proto_admin,     "#{opcache_proto}"
set :opcache_host_dest,       "127.0.0.1"
set :opcache_host_dest_www,   "#{opcache_host_dest}"
set :opcache_host_dest_admin, "#{opcache_host_dest}"
set :opcache_utility,         "curl"
set :opcache_utility_path,    "/usr/bin/#{opcache_utility}"
set :opcache_filename_www,    "apc_clear.php"
set :opcache_filename_admin,  "apc_clear_admin.php"


set :database_backup_dumpfile, "#{temp_folder}/#{application}.sql.gz"
set :release_chown, "no"

set :user, ""
set :use_sudo, false
set :ssh_options, { :forward_agent => true, :auth_methods => [%{publickey}] }
default_run_options[:pty] = true
default_run_options[:shell] = '/bin/bash'

set :reference, fetch(:reference, "").to_s
set :opts_debug, fetch(:opts_debug, "no").to_s

set :opts, {
  "code_only"               => fetch(:code_only, "no"),
  "clear_varnish"           => fetch(:clear_varnish, "no"),
  "clear_drush"             => fetch(:clear_drush, "yes"),
  "siteupdate"              => fetch(:siteupdate, "no"),
  "siteupdate_clear_drush"  => fetch(:siteupdate_clear_drush, "no"),
  "disable_cron"            => fetch(:disable_cron, "yes"),
  "maintenance"             => fetch(:maintenance, "yes"),
  "db_backup"               => fetch(:db_backup, "yes"),
  "db_optimize_cache_form"  => fetch(:db_optimize_cache_form, "no"),
}

def remote_file_exists?(path)
  results = []
  invoke_command("if [ -e '#{path}' ]; then echo -n 'true'; else echo -n 'false'; fi") do |ch, stream, out|
    out == "true" ? results << true : results << false
  end
  results.all?
end

Dir['config/deploy/recipes/*.rb'].each { |recipe| load(recipe) }

deployment_command_arguments_full = ARGV.clone
deployment_command_arguments = deployment_command_arguments_full.clone
if deployment_command_arguments[0].nil? or not stages.include? deployment_command_arguments[0]
  raise CommandError.new("Wrong stage specified")
end
if deployment_command_arguments[1].nil?
  raise CommandError.new("No command specified")
end
deployment_command_arguments.delete_at(0)
deployment_task = deployment_command_arguments.detect { |a| a.to_s !~ /\A-/ && a.to_s !~ /=/ }
set :deployment_task_not_sanitized, deployment_task
deployment_task = deployment_task.gsub(/[^\w\s]/, '_')

at_exit do
  unless File.directory?("log/")
    FileUtils.mkdir("log/")
  end
  reference_log_string = ""
  unless reference.empty?
    reference_log_string = "_#{reference}"
  end
  deployment_logfile = "log/#{release_name}_#{stage}_#{deployment_task}#{reference_log_string}.log"
  File.write(deployment_logfile, "Command arguments: #{deployment_command_arguments_full.join(' ')}\n" )
  File.write(deployment_logfile, full_log, mode: 'a')
  logger.info("Deployment log saved into #{File.expand_path(deployment_logfile)}")
end
