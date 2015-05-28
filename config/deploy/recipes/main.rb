namespace :deploy do

after "deploy:update", "deploy:optional", "deploy:cleanup"
after "deploy:finalize_update", "deploy:symlink_additional"

before "deploy", :roles => :web do
  validation.check
  validation.git
  if opts["code_only"] == "no"
    drush.disable               if opts["maintenance"] == "yes"
    drush.cron_disable          if opts["disable_cron"] == "yes"
  end
  database.optimize_cache_form  if opts["db_optimize_cache_form"] == "yes"
  database.backup               if opts["db_backup"] == "yes"
  deploy.setup
end



task :optional, :roles => :web do
  cache.opcache
  if opts["code_only"] == "no"
    if opts["siteupdate"] == "yes" || opts["siteupdate"] == "full"
      drush.updatedb         
      drush.cc               if opts["siteupdate_clear_drush"] == "yes"
      drush.fra
    elsif opts["siteupdate"] == "updatedb"
      drush.updatedb
    elsif opts["siteupdate"] == "fra"
      drush.cc               if opts["siteupdate_clear_drush"] == "yes"
      drush.fra
    end   
    drush.cc                 if opts["clear_drush"] == "yes"
    cache.varnish            if opts["clear_varnish"] == "yes"
    drush.enable             if opts["maintenance"] == "yes"
    drush.cron_enable        if opts["disable_cron"] == "yes"
  end
end



task :post_rollback, :roles => :web do
  if opts["code_only"] == "no"
    drush.enable                              if opts["maintenance"] == "yes"
    drush.cron_enable                         if opts["disable_cron"] == "yes"
  end
end



task :setup, :roles => :web do
  run "umask 02 && mkdir -p #{deploy_to} #{deploy_to}/releases #{resources_dir}"
  run "if [[ ! -d #{resources_dir}/#{drupal_folder_public} ]]; then mkdir #{resources_dir}/#{drupal_folder_public}; fi"
  run "if [[ ! -f #{resources_dir}/#{drupal_file_settings} ]]; then touch #{resources_dir}/#{drupal_file_settings}; fi"
  run "if [[ ! -d #{deploy_to}/#{temp_dir} ]]; then mkdir #{deploy_to}/#{temp_dir}; fi"
end



task :update, :roles => :web do
  transaction do
    update_code
    create_symlink
  end
end



task :update_code, :roles => :web, :except => { :no_release => true } do
  on_rollback { run "rm -rf #{release_path}; true" }
  strategy.deploy!
  finalize_update
end



task :finalize_update, :roles => :web do
  run "chmod -R g+w #{release_path};"
  run "mv #{release_path}/REVISION #{release_path}/REVISION.txt"
  run "#{try_sudo} /bin/chown -R #{webserver_user}:#{webserver_group} #{release_path}" if release_chown == "yes"
end



namespace :rollback do
  desc <<-DESC
    [internal] Points the current symlink at the previous revision.
    This is called by the rollback sequence, and should rarely (if
    ever) need to be called directly.
  DESC
  task :revision, :roles => :web, :except => { :no_release => true } do
    if previous_release
      run "#{try_sudo} rm #{current_path}; #{try_sudo} ln -s #{previous_release} #{current_path}"
    else
      abort "could not rollback the code because there is no prior release"
    end
  end

  desc <<-DESC
    [internal] Removes the most recently deployed release.
    This is called by the rollback sequence, and should rarely
    (if ever) need to be called directly.
  DESC
  task :cleanup, :roles => :web, :except => { :no_release => true } do
    run "if [ `readlink #{current_path}` != #{current_release} ]; then #{try_sudo} rm -rf #{current_release}; fi"
  end

  desc <<-DESC
    Rolls back to the previously deployed version. The `current' symlink will \
    be updated to point at the previously deployed version, and then the \
    current release will be removed from the servers. You'll generally want \
    to call `rollback' instead, as it performs a `restart' as well.
  DESC
  task :code, :roles => :web, :except => { :no_release => true } do
    revision
    cleanup
  end

  desc <<-DESC
    Rolls back to a previous version and restarts. This is handy if you ever \
    discover that you've deployed a lemon; `cap rollback' and you're right \
    back where you were, on the previously deployed version.
  DESC
  task :default, :roles => :web do
    revision
    restart
    cleanup
  end
end



task :create_symlink, :roles => :web, :except => { :no_release => true } do
  on_rollback do
    if previous_release
      run "#{try_sudo} rm -f #{current_path}; #{try_sudo} ln -s #{previous_release} #{current_path}; true"
    else
      logger.important "no previous release to rollback to, rollback of symlink skipped"
    end
  end

  run "#{try_sudo} rm -f #{current_path} && #{try_sudo} ln -s #{latest_release} #{current_path}"
end



task :symlink_additional, :roles => :web do
  if exists?(:symlink_additional_resources)
    symlink_additional_resources.each do |res|
      res.each {|k,v| run "ln -s #{k} #{v}" }
    end
  end
end



task :cleanup, :roles => :web, :except => { :no_release => true } do

  permissions_fix_pattern =  fetch(:permissions_fix_pattern, "install.php")
  permissions_fix_search_depth =  fetch(:permissions_fix_search_depth, "2")

  # sometimes release directory is Drupal subsite too and it changes permissions (-w)
  # need to restore them
  chmod_release_dir =  fetch(:chmod_release_dir, "no")

  count = fetch(:keep_releases, 5).to_i
  local_releases = capture("ls -xt #{releases_path}").split.reverse
  if count >= local_releases.length
    logger.important "no old releases to clean up"
  else
    logger.info "keeping #{count} of #{local_releases.length} deployed releases"
    directories = (local_releases - local_releases.last(count)).map { |release|
    File.join(releases_path, release) }.join(" ")

    directories.split(' ').each do | oldreleasedir |
      tmpreleasedir = oldreleasedir.chomp
      run "chmod u+w #{tmpreleasedir}" if chmod_release_dir == "yes"

      drupal_root = capture("find #{tmpreleasedir} -maxdepth #{permissions_fix_search_depth} -true -type f -name #{permissions_fix_pattern} | xargs -I {} dirname {}").gsub(/\r\n$/, "")
      drupal_root_processed = tmpreleasedir + drupal_root.split(tmpreleasedir).last.to_s

      run "if [[ -d #{drupal_root_processed}/sites/ ]]; then #{try_sudo} chmod u+w #{drupal_root_processed}/sites/*; find #{drupal_root_processed}/sites/ -maxdepth 2 -type f -name settings.php -print0 | xargs -I{} -0 #{try_sudo} chmod u+w {}; fi"
    end
    run "rm -rf #{directories}"
  end
end



task :restart, :roles => :web do
  # stub
end



end #namespace :deploy