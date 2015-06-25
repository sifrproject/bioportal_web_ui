jQuery(document).ready(function(){
  jQuery("#recommender_button").click(getRecommendations);
  jQuery("#insert_text_link").click(insertSampleText);
  jQuery("#insert_keywords_link").click(insertSampleKeywords);
});

function insertSampleText() {
  var text = 'Primary treatment of DCIS now includes 3 options: lumpectomy without lymph node surgery plus whole breast radiation (category 1); total mastectomy with or without sentinel node biopsy with or without reconstruction (category 2A); lumpectomy without lymph node surgery without radiation (category 2B). Workup for patients with clinical stage l, llA, llB, or T3,N1,M0 disease was reorganized to distinguish optional additional studies from those recommended for all of these patients. Recommendation for locoregional treatment for patients with clinical stage l, llA, llB, or T3,N1,M0 disease with 1-3 positive axillary nodes following total mastectomy was changed from "Consider" to "Strongly consider" postmastectomy radiation therapy. For patients with hormone receptor-positive, HER2-negative tumors that are 0.6-1.0 cm and moderately/poorly differentiated or with unfavorable features, or > 1 cm, the recommendation for use of a 21-gene RT-PCR assay (category 2B) was added to the systemic adjuvant treatment decision pathway as an option for guiding chemotherapy treatment decisions. Systemic adjuvant treatment for patients with tubular or colloid tumors that are hormone receptor-positive and node-positive was changed from "adjuvant hormonal therapy + adjuvant chemotherapy" to "adjuvant hormonal therapy adjuvant chemotherapy". For hormone receptor-positive, node negative tubular/colloid tumors that are 1 cm, the recommendation for use or consideration of adjuvant chemotherapy was removed. The heading for workup for patients with locally advanced invasive cancer was modified to specify "Noninflammatory" disease and reorganized to distinguish optional additional studies from those recommended for all of these patients.';
  jQuery("#recommendation_text").focus();
  jQuery("#recommendation_text").val(text);
}

function insertSampleKeywords() {
  var text = "fibroepithelial neoplasm \nsyndrome \ncarcinoma in situ \nDNA Damage \nhereditary disease \nRecruitment \nRetinal Neovascularization \nCerebrovascular accident \nhereditary Wilms' cancer \ncarcinoma \nAlzheimer's disease \nosteosarcoma \nmelanoma \nadenovirus infectious disease \nHypoalbuminemia \nAtaxia \nneurodegenerative disorder \ndisease \nobesity \ngenetic disorder \nRetinal degeneration \nBardet-Biedl syndrome \ndisorder \nGlaucoma \nprogressive multifocal leukoencephalopathy \nprimary biliary cirrhosis \ndisease by infectious agent \nviral infectious disease \ncancer \nrenal cell carcinoma \nlymphoma \nhepatitis B \nWithdrawal \nZellweger syndrome \nsevere mental retardation IQ 20-34 \ngroup B streptococcal pneumonia \nEmery-Dreifuss muscular dystrophy \ncardiomyopathy \ncutaneous mastocytosis \nmuscular atrophy \nIntestines \ncolon carcinoma \nHalo nevus \nleukemia \nacute myeloid leukemia \nepilepsy \nbreast carcinoma \nprimary carcinoma of the liver cells \nmalignant neoplasm of breast \ncontagious pustular dermatitis \nbasal cell carcinoma \nhypersensitivity \nretinoblastoma \nmyeloid leukemia \nheart defects, congenital \nlocally Advanced malignant neoplasm \naortic valve insufficiency \nnephroblastoma \nglioma \nglioblastoma \nanaplastic astrocytoma \nbrain edema \ndiabetes mellitus \nhypertension \nprogeria \nMuscle Rigidity \nBulla \nnephrotic syndrome \nLiver Cirrhosis \nInsulin Resistance \nKlinefelter's syndrome \nDependence \nmicrocytic anemia \nanemia \nT-cell leukemia \nretinitis pigmentosa \ncleft palate \nShprintzen syndrome \nDiGeorge syndrome \nHypocalcemia result \nbenign prostatic hypertrophy \ninfertility \novarian small cell carcinoma \ngiant cell tumor of bone \nDuchenne muscular dystrophy \nhereditary breast ovarian cancer \nataxia telangiectasia \nDental Plaque \nglycogen storage disease \nnasal polyps \nscleroderma \nsystemic scleroderma \nmalignant neoplasm of ovary \nSeborrheic keratosis \nactinic keratosis \nsquamous cell carcinoma \ncardiovascular system infectious disease \nAtherosclerosis \nmammary cancer \nPre-Eclampsia \n";
  jQuery("#recommendation_text").focus();
  jQuery("#recommendation_text").val(text);
}

function getRecommendations() {
  jQuery("#not_enough_text_error").html("");
  jQuery(".recommender_error").html("");
  jQuery(".recommender_spinner").show();

  var params = {};
  var ont_select = jQuery("#ontology_ontologyId");

  params.text = jQuery("#recommendation_text").val();
  params.ontologies = (ont_select.val() === null) ? [] : ont_select.val();
  params.hierarchy = jQuery("[name='hierarchy']:checked").val() == "none" ? "" : jQuery("[name='hierarchy']:checked").val();
  params.normalization = jQuery("[name='normalization']:checked").val() == "none" ? "" : jQuery("[name='normalization']:checked").val();

  jQuery.ajax({
    type: "POST",
    url: "/recommender_v1",
    data: params,
    dataType: "json",
    success: function(data) {
      // Really dumb, basic word counter. Counts spaces.
      if (jQuery("#recommendation_text").val().match(/ /g) == null || jQuery("#recommendation_text").val().match(/ /g).length < 50) {
        jQuery("#not_enough_text_error").html("Please use more than 50 words for accurate results");
      }
      // Create table headers
      var links = [];
      links.push('<thead><tr><th style="padding-right: 6px; text-align: right;">Rank</th><th>Ontology</th><th style="padding-right: 6px">Classes Matched</th></tr></thead>');
      // Populate table rows
      var resultCount = 1;
      if (jQuery.isEmptyObject(data)) {
        links.push("<tr><td>No recommendations found</td></tr>");
      } else {
        jQuery(data).each(function(){
          var rec = this;
          var ontName = rec.ontology.name + ' (' + rec.ontology.acronym + ')';
          var ontLink = rec.ontology.ui.replace(/.*ontologies/,'/ontologies');
          var termsStr = rec.numTermsMatched + " of " + rec.numTermsTotal; // + " (score=" + rec.score + ")";
          //var foundConceptsID = 'found_concepts_' + resultCount;
          // Populate a facebox popup with matched concepts
          //
          // TODO: ENABLE CLASSES MATCHED WHEN THE REST /batch IS RELIABLE.
          // TODO: Consider retrieving all the class details only when requested using ajax.
          //
          //var found_concepts = [];
          //jQuery.each(rec.annotatedClasses, function(){
          //  found_concepts.push("<a href='"+ontLink+"?p=classes&conceptid="+encodeURIComponent(this.id)+"'>"+this.prefLabel+"</a>");
          //});
          //var found_concepts_html = "" +
          //  "<div id='" + foundConceptsID + "' class='found_concepts'>" +
          //    "<h2 style='margin-top: -2em;'>Matched Classes</h2>" +
          //    found_concepts.join("<br/>") +
          //  "</div>";
          // Create a row entry: rank, ontology, counts
          links.push(
            "<tr>" +
              "<td style='text-align: right; padding-right: 10px;'>" + resultCount + "</td>" +
              "<td style='padding: 6px 12px 6px 12px;'>" + "<a href='" + ontLink + "'>" + ontName + "</a>" + "</td>" +
              "<td style='text-align: right;'>" +
                //"<a href='#" + foundConceptsID + "' rel='facebox'>" + termsStr + "</a>" + found_concepts_html +
                termsStr +
              "</td>" +
            "</tr>"
          );
          resultCount++;
        });
      }
      jQuery(".recommender_spinner").hide();
      jQuery("#recommendations").html(links.join(""));
      jQuery("#recommendations_container").show();
      // Wire concept modal dialog
      //jQuery("a[rel*=facebox]").facebox();
    },
    error: function(data) {
      jQuery("#recommendations_container").hide();
      jQuery(".recommender_spinner").hide();
      jQuery(".recommender_error").html(" Problem getting recommendations, please try again");
    }
  });
}

