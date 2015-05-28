namespace :database do


  task :backup, :roles => :web do
    if exists?(:db_backup_slave) && db_backup_slave == "yes"
      db_server = db_host_slave
      logger.info "Performing database dump from SLAVE server (#{db_server})"
    else
      db_server = db_host_master
      logger.info "Performing database dump from MASTER server (#{db_server})"
    end
    run "/usr/bin/mysqldump --single-transaction --skip-lock-tables --skip-add-locks -u#{db_user} -p#{db_password} -h#{db_server} #{db_name} | gzip --fast > #{database_backup_dumpfile}", :once => true
  end



  task :optimize_cache_form, :roles => :web do
    run "/usr/bin/mysql -u#{db_user} -p#{db_password} -h#{db_host_master} #{db_name} -e 'DELETE FROM cache_form where expire < UNIX_TIMESTAMP(NOW()) ; OPTIMIZE TABLE cache_form ;'", :once => true
  end



  task :optimize_full, :roles => :web do
    run "/usr/bin/mysqlcheck -o -u#{db_user} -p#{db_password} -h#{db_host_master} #{db_name}", :once => true
  end


end # namespace :database