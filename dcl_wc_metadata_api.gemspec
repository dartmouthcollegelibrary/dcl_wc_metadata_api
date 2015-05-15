Gem::Specification.new do |s|
   s.name = 'dcl_wc_metadata_api'
   s.version = '0.0.1'
   s.author = ['Shaun Akhtar']
   s.email = ['shaun.y.akhtar@dartmouth.edu']
   s.summary = 'DCL-local WorldCat Metadata API tools'
   s.files = Dir.glob("{lib,config}/**/*")
   s.executables = ['dcl-wc-metadata-api']
   s.require_path = 'lib'
   s.add_dependency 'json', '~> 1.8', '>= 1.8.1'
   s.add_dependency 'rest-client', '~> 1.6', '>= 1.6.7'
   s.has_rdoc = false
   s.date = '2015-04-10'
   s.license = 'Apache 2'
   s.description = "Dartmouth College Library scripts using Terry Reese's wc_metadata_api and OCLC's oclc-auth-ruby gems."
end

