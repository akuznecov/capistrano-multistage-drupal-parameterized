namespace :cache do



task :varnish, :roles => :web do

  run "#{varnishadm_path} #{varnishadm_options} ban \"#{varnishadm_pattern}\""

end #task varnish



task :opcache, :roles => :web do

  randomstring  =  (("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a).to_a.shuffle.first(5).join

  case opcache_opcoder 
  when "apc"
    opcache_script_line = "<?php if ( $_SERVER['REMOTE_ADDR'] == '127.0.0.1' ) { apc_clear_cache(); apc_clear_cache('user'); apc_clear_cache('opcode'); echo json_encode(array('success' => true)); } ?>"
  when "opcache"
    opcache_script_line = "<?php if ( $_SERVER['REMOTE_ADDR'] == '127.0.0.1' ) { opcache_reset(); echo json_encode(array('success' => true)); } ?>"
  end

  unless remote_file_exists?("#{opcache_path}/#{opcache_filename_www}")
    logger.info "Cache clear script for www pool are not present. Uploading it."
    put opcache_script_line, "#{opcache_path}/#{opcache_filename_www}"
  else
    logger.info "Cache clear script for www pool already present. No need to upload."
  end

  unless remote_file_exists?("#{opcache_path}/#{opcache_filename_admin}")
    logger.info "Cache clear script for admin pool are not present. Uploading it."
    put opcache_script_line, "#{opcache_path}/#{opcache_filename_admin}"
  else
    logger.info "Cache clear script for admin pool already present. No need to upload."
  end

  opcode_command = "#{opcache_utility_path} "

  case opcache_utility 
  when "wget"
    opcode_command = opcode_command + "-nv -O- --header 'Host: #{opcache_site_address}' "
    if exists?(:opcache_utility_user) && exists?(:opcache_utility_password)
      opcode_command = opcode_command + "--http-user='#{opcache_utility_user}' --http-password='#{opcache_utility_password}' "
    end
  when "curl"
    opcode_command = opcode_command + "-k --ipv4 --noproxy '*' -H 'Host:#{opcache_site_address}' "
    if exists?(:opcache_utility_user) && exists?(:opcache_utility_password)
      opcode_command = opcode_command + "--user #{opcache_utility_user}:#{opcache_utility_password} "
    end
  end

  opcode_command_www   = opcode_command + "'#{opcache_proto_www}://#{opcache_host_dest_www}/#{opcache_filename_www}?#{randomstring}'"
  opcode_command_admin = opcode_command + "'#{opcache_proto_admin}://#{opcache_host_dest_www}/#{opcache_filename_admin}?#{randomstring}'"

  run "#{opcode_command_www}"
  run "#{opcode_command_admin}"

end #task opcache




end #namespace cache