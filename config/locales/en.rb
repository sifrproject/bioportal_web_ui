{
  :en => {
    :home => {
      :intro => 'Use ' + $SITE + ' to access and share French biomedical ontologies and terminologies. You can <a href="/annotate">create ontology-based 
        annotations for your own text </a>, <a href = "/projects"> link your own project that uses ontologies to the 
        description of  those ontologies </a>, <a href = "/mappings">find and create relations between terms in 
        different ontologies</a>, review and comment on ontologies and their components as you 
        <a href="/ontologies">browse</a> them.  <a href="/login">Sign in to ' + $SITE + '</a>
        to submit a new ontology or ontology-based project, provide comments on ontologies or add ontology mappings.',
        
      :facebook_button => '',
      
      :twitter_button => '',

      :annotate => {
        :intro => 'The ' + $ORG_SITE + ' Annotator processes text submitted by users, recognizes relevant ontology terms in the text and returns 
          the annotations to the user. Use the interface below to submit sample text to get ontology-based annotations. Hover the mouse pointer on any 
          button to see what it does.',
	:ncbo => 'The NCBO Annotator+ is a proxy calling the NCBO Annotator Web service on the NCBO BioPortal. This proxy enables to use new Annotators features such as scoring [Melzi & Jonquet 2014] or RDF outputs [Melzi & Jonquet 2014].</br>
If using the API, please provide a valid NCBO BioPortal apikey and hit the service at <a href="http://services.bioportal.lirmm.fr/ncbo_annotatorplus">http://services.bioportal.lirmm.fr/ncbo_annotatorplus</a></br>
Text submitted to the NCBO Annotator+ must be in English.'
      },
      
      :resources => {
        :intro => $ORG + ' is building a system for automated ontology-based annotation and indexing of data. We process the textual metadata of diverse elements of resources 
          to annotate and index them with terms from appropriate ontologies. Use the interface below to search the resulting index of annotations and to identify 
          data resources annotated with particular ontology terms.'
      },
      
      :footer => '<a title="Powered by NCBO BioPortal" href="http://bioportal.bioontology.org/">Powered by NCBO BioPortal</a>'
    },
    
    :projects => {
      :intro => 'Browse the ontology-based projects in the community:</b> Each project description is linked to ' + $ORG_SITE + ' ontologies that the project uses.  
        Use the ‘Add Project’ link to add your ontology-based project to this list and to link it to ' + $ORG_SITE + ' ontologies. 
        Your project will then appear on the pages that list the details for the ontologies that you selected. We also invite you to review ontologies that you used in your project.'
    },
    
    :ontologies => {
      :intro => '<b>Access all ontologies that are available in ' + $ORG_SITE + ':</b>
        You can filter this list by category to display ontologies relevant for a certain domain. 
        You can also filter ontologies that belong to a certain group. <a href = "feed://syndication/rss">Subscribe to the ' + $ORG_SITE + ' RSS feed</a>
        to receive alerts for submissions of new ontologies, new versions of ontologies, new notes, and new projects. You can subscribe to feeds for a specific ontology at 
        the individual ontology page. Add a new ontology to ' + $ORG_SITE + ' using the Submit New Ontology link (you need to <a href= "/login">sign in</a>
        to see this link).',
        
      :metrics => {
        :intro => '' + $SITE + ' calculates the metrics on the salient properties of the ontology, including statistics and quality-control
          and quality-assurance metrics. Each ontology may have all, some, or no values filled in for its metrics and only metrics
          for the most recent version are reflected. The metrics currently do not distinguish between the terms defined directly in
          this ontology and imported terms (for OWL) or referenced terms (for OBO).
          <a target="_blank" href="http://www.bioontology.org/wiki/index.php/Ontology_Metrics">See metrics descriptions</a>.'
      } 
    },
    
    :mappings => {
      :intro => 'Use this page to explore mappings between ontologies that you are interested in. You will also see the mappings when you browse individual ontologies.'
    },
    
    :about => {
      :welcome => "Le SIFR BioPortal, une plateforme ouverte et générique pour l’hébergement d’ontologies et de terminologies biomédicales françaises, basée sur la technologie du National Center for Biomedical Ontology. Le portail facilite l’usage et la diffusion des ontologies du domaine en offrant un ensemble de services (recherche, alignements, métadonnées, versionnement, visualisation, recommandation) y inclus pour l’annotation sémantique. En effet, le SIFR Annotator est un outil pour traiter des données textuelles en français.",
      :getting_started => $SITE + " permet à ses utilisateurs d'exploiter des ontologies mises en ligne : explorer, télécharger, commenter, rechercher des concepts, créer des mappings.",
      :browse => "
        <p>
            Les utilisateurs peuvent explorer des ontologies sous forme d'arborescence, accéder à leur méta-données et les télécharger. 
        </p>",
      :announce_list => "Pour nous faire part de tout commentaires ou besoin de supports, contactez-nous à l'adresse suivante: <a href='" + $SUPPORT_LIST + "'>" + $SUPPORT_LIST + "</a>. Vous pouvez également vous inscrire à notre <a href='sifrportal-users@lirmm.fr'>liste de diffusion</a>.",
      :release_notes => ''
    },
 
    :most_viewed_date => 'March, 2012',
    
    :most_viewed => 
      '<table class="minimal" width="100%">
        <thead>
        <tr>
          <th>Ontology</th>
          <th>Views</th>
        </tr>
        </thead>
              <tbody><tr>
                  <td><a href=""></a></td>
                  <td></td>
              </tr>
              <tr>
                  <td><a href=""></a></td>
                  <td></td>
              </tr>
              <tr>
                  <td><a href=""></a></td>
                  <td></td>
              </tr>
              <tr>
  
                  <td><a href=""></a></td>
                  <td></td>
              </tr>
              <tr>
                  <td><a href=""></a></td>
                  <td></td>
              </tr>
        </tbody>
      </table>',
      
    :stats => 
      ''
  }
}
