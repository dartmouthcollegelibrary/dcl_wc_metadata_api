Gem::Specification.new do |s|
   s.name = 'dcl_wc_metadata_api'
   s.version = '0.2.3'
   s.author = ['Shaun Akhtar']
   s.email = ['shaun.y.akhtar@dartmouth.edu']
   s.summary = 'DCL-local WorldCat Metadata API tools'
   s.files = Dir.glob("lib/**/*") + Dir.glob("{LICENSE,README.md}")
   s.executables = ['dcl-wc-metadata-api']
   s.require_path = 'lib'
   s.add_dependency 'json', '~> 2.0', '>= 2.0.3'
   s.add_dependency 'nokogiri', '~> 1.6', '>=1.6.3'
   s.add_dependency 'rest-client', '~> 2.0', '>= 2.0.1'
   s.has_rdoc = false
   s.date = '2017-09-25'
   s.license = 'Apache-2.0'
   s.homepage = 'https://github.com/dartmouthcollegelibrary/dcl_wc_metadata_api'
   s.description = "Dartmouth College Library scripts using Terry Reese's wc_metadata_api and OCLC's oclc-auth-ruby gems."
end
