# coding: utf-8

# Organization info
$ORG = "NCBO"
$ORG_URL = "http://www.bioontology.org"

# Site name (required)
$SITE = "BioPortal"

# The URL for the BioPortal Rails UI (this application)
$UI_URL = "http://localhost:3000"

# Full string for site, EX: "NCBO BioPortal" (auto-generated, don't modify)
$ORG_SITE = ($ORG.nil? || $ORG.empty?) ? $SITE : "#{$ORG} #{$SITE}"

# If you are running a PURL server to provide URLs for ontologies in your BioPortal instance, enable this option
$PURL_ENABLED = true

# The PURL URL is generated using this prefix + the abbreviation for an ontology.
# The PURL URL generation algorithm can be altered in
$PURL_PREFIX = "http://purl.bioontology.org/ontology"

# If your BioPortal installation includes Annotator set this to false
$ANNOTATOR_DISABLED = false

# If your BioPortal installation includes Resource Index set this to false
$RESOURCE_INDEX_DISABLED = false

$USER_INTENTION_SURVEY = nil

$MAX_CHILDREN = 2500

# Max number of children that it's possible to display (more than this is either too slow or not helpful to users)
$MAX_POSSIBLE_DISPLAY = 10000

# Application ID: unique string representing the UI's id for use with the Core
$API_KEY = "8b5b7825-538d-40e0-9e9e-5ab9274a9aeb" # prod ui
# $API_KEY = "24e0e77e-54e0-11e0-9d7b-005056aa3316" # mine
# $API_KEY = "f68a3f4a-ade1-44d6-960e-f990ab2e21c1" # VM Appliance
# $API_KEY = "1de0a270-29c5-4dda-b043-7c3580628cd5" # Mallet API Key

# $REST_URL = "http://localhost:9393"
# $REST_URL = "http://ncbo-appliance-api2:8082"
# $REST_URL = "http://stagedata.bioontology.org"
# $REST_URL = "http://ncbostage-rest2:8080"
# $REST_URL = "http://localhost:8080"
$REST_URL = "http://data.bioontology.org"
# $REST_URL = "http://ncboprod-rest2"
# $REST_URL = "http://ec2-54-212-153-101.us-west-2.compute.amazonaws.com:8080" # mallet AMI

# Enable client request caching
$CLIENT_REQUEST_CACHING = true

# Old REST core service address
$LEGACY_REST_URL="http://rest.bioontology.org/bioportal"
# $LEGACY_REST_URL="http://stagerest.bioontology.org/bioportal"

# REST core service port number
$REST_PORT="80"
# $REST_PORT="8080"

# Cube metrics reporting
$ENABLE_CUBE = true
$CUBE_HOST = "192.241.195.36"

# A user id for user 'anonymous' for use when a user is required for an action on the REST service but you don't want to require a user to login
$ANONYMOUS_USER = 39917

$AIRBRAKE_API_KEY = "54eadfa4bbf9c8a08acb3d9d96624024"

$ONTOLOGY_SLICES = {
  "test" => { :name => "Test Site", :ontologies => [1032, 1054, 1099] }
}

$ENABLE_SLICES = true

# Max size allowed for uploaded files
$MAX_UPLOAD_SIZE = 1073741824

# Enables a help page maintained elsewhere that is read and displayed. Content is stored in a div with id 'bodyContent'.
$WIKI_HELP_PAGE = "http://www.bioontology.org/wiki/index.php/BioPortal_Help"


# OBR REST service address
#$RESOURCE_INDEX_REST_URL="http://rest.bioontology.org/resource_index"
$RESOURCE_INDEX_REST_URL="http://stagerest.bioontology.org/resource_index"
#$RESOURCE_INDEX_REST_URL="http://ncbodev-obr1.stanford.edu:8080/resource_index"

# Resource Index UI Location
$RESOURCE_INDEX_UI_URL = "http://localhost/riui/"

# Release version text (appears in footer of all pages)
$RELEASE_VERSION = "Release 2.2.1 (released October 19th, 2009)"

# SMTP settings
ActionMailer::Base.smtp_settings = {
  :address  => "smtp-unencrypted.stanford.edu", # smtp server address, ex: smtp.domain.com
  :port  => 25, # smtp server port
  :domain  => "ncbo-ror-prod1.stanford.edu", # fqdn of rails server, ex: rails.domain.com
}

# Email address to mail when exceptions are raised
begin
  ExceptionNotifier.exception_recipients = %w(palexander@stanford.edu)
rescue; end

# Announcements mailman mailing list REQUEST address, EX: list-request@lists.example.org
# NOTE: You must use the REQUEST address for the mailing list. ONLY WORKS WITH MAILMAN LISTS.
$ANNOUNCE_LIST = "bioportal-test-request@lists.stanford.edu"

# Email addresses used for sending notifications (errors, feedback, support)
$SUPPORT_EMAIL = "palexander@stanford.edu"
$ADMIN_EMAIL = "palexander@stanford.edu"
$ERROR_EMAIL = "palexander@stanford.edu"

# Remote logging
require 'log'
$REMOTE_LOGGING = false

# reCAPTCHA
# In order to use reCAPTCHA on the user account creation page:
#    1. Obtain a key from reCAPTCHA: http://recaptcha.net
#    2. Include the corresponding keys below (between the single quotes)
#    3. Set the USE_RECAPTCHA option to 'true'
ENV['USE_RECAPTCHA'] = 'true'
ENV['RECAPTCHA_PUBLIC_KEY']  = '6LeJhQgAAAAAAPA9Q_sYaV1ObNJrVzuRZIcxLrep'
ENV['RECAPTCHA_PRIVATE_KEY'] = '6LeJhQgAAAAAADBhw7Ep3jqxAzNur2WjHR2TKoXr'

# Increment the following 'version' to prevent caching when Flex apps are updated
$FLEX_VERSION="1.0.8"

$ANNOTATOR_FLEX_APIKEY = "24e0e77e-54e0-11e0-9d7b-005056aa3316"

$SEARCH_FLEX_APIKEY = "24e0e77e-54e0-11e0-9d7b-005056aa3316"

$RECOMMENDER_FLEX_APIKEY = "24e0e77e-54e0-11e0-9d7b-005056aa3316"

$FLEXOVIZ_APIKEY = "24e0e77e-54e0-11e0-9d7b-005056aa3316"

# URL to pull flex apps from
$FLEX_URL = "http://stage.bioontology.org/flex"

# URL where BioMixer GWT app is located
$BIOMIXER_URL = "http://bioportal-integration-test.bio-mixer.appspot.com"

$NOT_EXPLORABLE = [ 1042, 1423, 1429, 1426, 1424, 1504, 1499, 1529, 1527, 1351, 2066, 2040, 1020, 1397, 3196 ]

$NOT_DOWNLOADABLE = [ 1353 ]

$VERSIONS_IN_VIRTUAL_SPACE = Set.new([3905, 4525, 4531, 8056])

$VIRTUAL_ID_UPPER_LIMIT = 9999

$FRONT_NOTICE = ''

$SITE_NOTICE = { }

$FLEX_LOG = "&log=true"

##
# Custom Ontology Details
# Custom details can be added on a per ontology basis using a key/value pair as columns of the details table
#
# Example:
# $ADDITIONAL_ONTOLOGY_DETAILS = { 1000 => { "Additional Detail" => "Text to be shown in the right-hand column." } }
##

UMLS_LICENSE = <<-EOS
This ontology is made available via the UMLS. Users of all UMLS ontologies must abide by the terms of the UMLS license, available at <a href="https://uts.nlm.nih.gov/license.html">https://uts.nlm.nih.gov/license.html</a>
EOS

$ADDITIONAL_ONTOLOGY_DETAILS = {
  "NCIT"        => { 'License Information' => UMLS_LICENSE },
  "FMA"         => { 'License Information' => UMLS_LICENSE },
  "ICD9CM"      => { 'License Information' => UMLS_LICENSE },
  "NCBITAXON"   => { 'License Information' => UMLS_LICENSE },
  "COSTART"     => { 'License Information' => UMLS_LICENSE },
  "ICPC"        => { 'License Information' => UMLS_LICENSE },
  "MEDLINEPLUS" => { 'License Information' => UMLS_LICENSE },
  "OMIM"        => { 'License Information' => UMLS_LICENSE },
  "PDQ"         => { 'License Information' => UMLS_LICENSE },
  "LOINC"       => { 'License Information' => UMLS_LICENSE },
  "MESH"        => { 'License Information' => UMLS_LICENSE },
  "NDFRT"       => { 'License Information' => UMLS_LICENSE },
  "SNOMEDCT"    => { 'License Information' => UMLS_LICENSE },
  "WHO-ART"     => { 'License Information' => UMLS_LICENSE },
  "MEDDRA"      => { 'License Information' => UMLS_LICENSE },
  "RXNORM"      => { 'License Information' => UMLS_LICENSE },
  "NDDF"        => { 'License Information' => UMLS_LICENSE },
  "ICD10PCS"    => { 'License Information' => UMLS_LICENSE },
  "MDDB"        => { 'License Information' => UMLS_LICENSE },
  "RCD"         => { 'License Information' => UMLS_LICENSE },
  "NIC"         => { 'License Information' => UMLS_LICENSE },
  "ICPC2P"      => { 'License Information' => UMLS_LICENSE },
  "AI-RHEUM"    => { 'License Information' => UMLS_LICENSE },
  "CPT"         => { 'License Information' => UMLS_LICENSE },
  "CPTH"        => { 'License Information' => UMLS_LICENSE },
  "ICD10"       => { 'License Information' => UMLS_LICENSE },
  "CRISP"       => { 'License Information' => UMLS_LICENSE },
  "VANDF"       => { 'License Information' => UMLS_LICENSE },
  "HCPCS"       => { 'License Information' => 'The MedDRA ontology is maintained and distributed by the <a href="http://www.meddramsso.com/" target="_blank">MedDRA MSSO</a>. This ontology is freely accessible on this site for academic and other non-commercial uses. Users anticipating any commercial use of MedDRA must contact the MSSO to obtain a license.' },
  "BAO"         => { 'License Information' => '<div class="enable-lists">Classes, properties and individuals in the VIVO namespace (http://vivoweb.org/ontology/core#) are licensed under the Creative Commons 3.0 BY license (http://creativecommons.org/licenses/by/3.0/)<br><br>The VIVO ontology package includes terms derived from the following namespaces used under the following licenses:<ul><li>http://purl.org/ontology/bibo/ - Creative Commons 3.0<br>license statement based on http://bibliontology.com/</li><li>http://purl.org/dc/elements/1.1/ - Creative Commons Attribution 3.0 Unported License<br>license statement based on http://dublincore.org/documents/dcmi-terms/</li><li>http://purl.org/dc/terms/ - Creative Commons Attribution 3.0 Unported License<br>license statement based on http://dublincore.org/documents/dcmi-terms/</li><li>http://purl.org/NET/c4dm/event.owl# - Creative Commons 1.0<br>license statement based on http://motools.sourceforge.net/event/event.html</li><li>http://aims.fao.org/aos/geopolitical.owl# - The use of this ontology is governed by the FAO copyright (http://www.fao.org/corp/copyright/en/)<br>license statement based on http://www.fao.org/countryprofiles/geoinfo.asp</li><li>http://xmlns.com/foaf/0.1/ - Creative Commons 1.0<br>license statement based on http://xmlns.com/foaf/spec/</li><li>http://www.w3.org/2004/02/skos/core# - Copyright ©2009 W3C® (MIT, ERCIM, Keio), All Rights Reserved. W3C liability, trademark and document use rules apply<br>license statement based on http://www.w3.org/TR/swbp-skos-core-guide</li><li>http://www.w3.org/2008/05/skos# - Copyright ©2009 W3C® (MIT, ERCIM, Keio), All Rights Reserved. W3C liability, trademark and document use rules apply<br>license statement based on http://www.w3.org/TR/swbp-skos-core-guide</li><li>http://purl.obolibrary.org/obo/ - Creative Commons 3.0 BY<br>license statement based on http://code.google.com/p/eagle-i/</li></ul></div>' },
  "ICD10CM"     => { 'License Information' => 'The version of the NCI Thesaurus (NCIt) available in BioPortal has been modified by reformatting some property values so that they can be more easily browsed (replacing or removing embedded XML). The original, unmodified NCIt, as well as NCIt license information, is available at <a href="http://ncit.nci.nih.gov">http://ncit.nci.nih.gov</a>.' },
  "VIVO"        => { 'License Information' => 'This ontology is made available under the <a href="http://creativecommons.org/licenses/by/3.0/us/">Creative Commons Attribution License Version 3</a>' },
  "BAO-GPCR"    => { 'License Information' => 'This ontology is made available under the <a href="http://creativecommons.org/licenses/by/3.0/us/">Creative Commons Attribution License Version 3</a>' }
}

