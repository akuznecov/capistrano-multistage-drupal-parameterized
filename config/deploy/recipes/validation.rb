namespace :validation do
  

task :check do

  if opts_debug == "yes"
    opts.sort.each do |k,v|
      logger.debug "#{k} => #{v}"
    end
  end

  raise CommandError.new("Variable 'opcache_site_address' not defined. Please define it inside of deployment script") unless exists?(:opcache_site_address)

  opts.each do |k,v|
    if k != "siteupdate"
      raise CommandError.new("Wrong value '#{v}' for variable '#{k}'. Please define as [y,Y,yes,YES] or [n,N,no,NO]") unless v.to_s.downcase.match(/^(n|no|y|yes)$/)
    else
      raise CommandError.new("Wrong value '#{v}' for variable '#{k}'. Valid values are [y,Y,yes,YES,n,N,no,NO,full,updatedb,fra]") unless v.to_s.downcase.match(/^(n|no|y|yes|full|updatedb|fra)$/)
    end
  end

  logger.info "All variables passed validation"

end # task check




task :git do

  raise CommandError.new("Reference not defined. Please specify it with reference=TAG (TAG should be provided by developer)") if reference.empty?

  if reference =~ /\A(([0-9a-f]{40})|([0-9a-f]{6,8}))\z/
    logger.info("Reference matched SHA1 hash")
    logger.info("We are unable to check if this commit present on remote repository")
    set :branch, reference
  else 
    gitref = `git ls-remote #{repository} | grep -v '\\^{}' | grep "/#{reference}$"`
    if not gitref.empty?
      if gitref.match('tag')
        logger.info("Reference found as tag. Falling back to SHA1 hash to support Git < 1.7.10")
        set :branch, gitref.split.first
      else
        set :branch, reference
      end
    else
      raise CommandError.new("Reference not found in repository")
    end
  end

  logger.info("Revision for deployment: #{branch}")

end # task git


end #namespace :validation