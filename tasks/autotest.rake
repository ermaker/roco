task :autotest do
  ENV['RSPEC'] = 'true'
  sh "autotest"
end

