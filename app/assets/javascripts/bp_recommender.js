// Namespace for global variables and functions
var rec = { }
rec.maxInputWords = 500;

rec.showOrHideAdvancedOptions = function() {
    $("#advancedOptions").toggle();
}

rec.insertInput = function() {
    rec.prepareForRealInput();
    if ($("#radioItText").is(":checked")) {
        rec.insertSampleText()
    }
    else {
        rec.insertSampleKeywords()
    }
}

rec.defaultMessage = true;
rec.prepareForRealInput = function() {
    $("#inputText").removeClass()
    rec.emptyInput = false;
    if (rec.defaultMessage == true) {
        $("#inputText").val('');
        rec.defaultMessage = false;
    }
}

rec.enableEdition = function() {
    $("#inputText").show();
    $("#inputTextHighlighted").hide();
    $("#resultsHeader").empty();
    $("#results").empty();
    $("#editButton").hide();
    $("#recommenderButton").show();
    $("input[name=input_type]").attr("disabled",false);
}

rec.insertSampleText = function() {
    rec.enableEdition();
    var text = 'Primary treatment of DCIS now includes 3 options: lumpectomy without lymph node surgery plus whole breast radiation (category 1); total mastectomy with or without sentinel node biopsy with or without reconstruction (category 2A); lumpectomy without lymph node surgery without radiation (category 2B). Workup for patients with clinical stage l, llA, llB, or T3,N1,M0 disease was reorganized to distinguish optional additional studies from those recommended for all of these patients. Recommendation for locoregional treatment for patients with clinical stage l, llA, llB, or T3,N1,M0 disease with 1-3 positive axillary nodes following total mastectomy was changed from "Consider" to "Strongly consider" postmastectomy radiation therapy. ';
    jQuery("#inputText").focus();
    jQuery("#inputText").val(text);
    $(".notTextError").hide();
    $("#radioItText").prop("checked", true);
}

rec.insertSampleKeywords = function() {
    rec.enableEdition();
    var text = "Backpain, White blood cell, Carcinoma, Cavity of stomach, Ductal Carcinoma in Situ, Adjuvant chemotherapy, Axillary lymph node staging, Mastectomy, tamoxifen, serotonin reuptake inhibitors, Invasive Breast Cancer, hormone receptor positive breast cancer, ovarian ablation, premenopausal women, surgical management, biopsy of breast tumor, Fine needle aspiration, entinel lymph node, breast preservation, adjuvant radiation therapy, prechemotherapy, Inflammatory Breast Cancer, ovarian failure, Bone scan, lumpectomy, brain metastases, pericardial effusion, aromatase inhibitor, postmenopausal, Palliative care, Guidelines, Stage IV breast cancer disease, Trastuzumab, Breast MRI examination";
    jQuery("#inputText").focus();
    jQuery("#inputText").val(text);
    $(".notTextError").hide();
    $("#radioItKeywords").prop("checked", true);
}

rec.colors = ["#76A7CC" , "#cc0000", "#339900", "#ff9900"];
rec.getHighlightedTerms = function(data, rowNumber) {
    var inputText = document.getElementById("inputText").value;
    var newText = '';
    var lastPosition = 0;
    var ontologyIds = [ ];
    for (var k = 0; k < data[rowNumber].ontologies.length; k++) {
        ontologyIds[k] = data[rowNumber].ontologies[k]["@id"];
    }
    for (var j = 0; j < data[rowNumber].coverageResult.annotations.length; j++) {
        var from = data[rowNumber].coverageResult.annotations[j].from-1;
        var to = data[rowNumber].coverageResult.annotations[j].to;
        var link = data[rowNumber].coverageResult.annotations[j].annotatedClass.links.ui;
        var term = inputText.substring(from, to);
        // Color selection - Single ontology
        if (data[rowNumber].ontologies.length == 1) {
            var color = rec.colors[0];
        }
        // Color selection - Set of ontologies
        else {
            var ontologyId = data[rowNumber].coverageResult.annotations[j].annotatedClass.links.ontology;
            var index = ontologyIds.indexOf(ontologyId);
            var color = rec.colors[index];
        }

        var replacement = '<a style="font-weight: bold; color:' + color + '" target="_blank" href=' + link + '>' + term + '</a>';

        if (from>lastPosition) {
            newText+=inputText.substring(lastPosition, from);
        }
        newText += replacement;
        lastPosition = to;
    }

    if (lastPosition < inputText.length) {
        newText += inputText.substring(lastPosition, inputText.length);
    }
    return newText;
}

rec.hideErrorMessages = function() {
    $(".generalError").hide();
    $(".inputSizeError").hide();
    $(".invalidWeightsError").hide();
    $(".rangeWeightsError").hide();
    $(".sumWeightsError").hide();
    $(".maxOntologiesError").hide();
    $(".invalidMaxOntError").hide();
    $(".notTextError").hide();
    $("#noResults").hide();
    $("#noResultsSets").hide();
}

rec.getRecommendations = function() {
    rec.hideErrorMessages();
    var errors = false;
    // Checks if the input text field is empty
    if (($("#inputText").val().length == 0) || (rec.emptyInput==true))  {
        $(".notTextError").show();
        errors = true;
    }
    // Checks the input size using a basic word counter
    if ($("#inputText").val().split(' ').length > rec.maxInputWords) {
        $(".inputSizeError").show();
        errors = true;
    }
    var wc = parseFloat($("#input_wc").val());
    var wa = parseFloat($("#input_wa").val());
    var wd = parseFloat($("#input_wd").val());
    var ws = parseFloat($("#input_ws").val());
    // Parameters validation
    if (isNaN(wc)||isNaN(wa)||isNaN(wd)||isNaN(ws)) {
        $(".invalidWeightsError").show();
        errors = true;
    }

    if ((wc < 0)||(wa < 0)||(wd < 0)||(ws < 0)) {
        $(".rangeWeightsError").show();
        errors = true;
    }

    if (wc + wa + wd + ws <= 0) {
        $(".sumWeightsError").show();
        errors = true;
    }

    var maxOntologies = parseInt($('#input_max_ontologies').val());

    if (isNaN(maxOntologies)||(maxOntologies%1!=0)) {
        $(".invalidMaxOntError").show();
        errors = true;
    }

    if ((maxOntologies < 2)||(maxOntologies > 4)) {
        $(".maxOntologiesError").show();
        errors = true;
    }

    if (!errors) {
        rec.hideErrorMessages();
        $(".recommenderSpinner").show();
        var params = {};
        var ont_select = jQuery("#ontology_ontologyId");
        params.input = $("#inputText").val();
        params.ontologies = (ont_select.val() === null) ? [] : ont_select.val();
        // Input type (text or keywords)
        if ($("#radioItText").is(":checked"))
            params.input_type = 1; //text
        else
            params.input_type = 2; //keywords
        // Output type (ontologies or ontology sets)
        if ($("#radioOtSingle").is(":checked"))
            params.output_type = 1; //ontologies
        else
            params.output_type = 2; //ontology sets
        // Weights
        params.wc = $("#input_wc").val();
        params.wa = $("#input_wa").val();
        params.wd = $("#input_wd").val();
        params.ws = $("#input_ws").val();
        // Maximum number of ontologies per set (only for the "ontology sets" output)
        params.max_elements_set = $('#input_max_ontologies').val();
        $.ajax({
            type: "POST",
            url: "/recommender",
            data: params,
            dataType: "json",
            success: function(data) {
                $('.recommenderSpinner').hide();
                if (data) {
                    if (data.length > 0) {
                        $("#results").empty();
                        $("#resultsHeader").text("Recommended ontologies");

                        if (params.output_type == 1) {
                            var ontologyHeader = "Ontology";
                        }
                        else {
                            ontologyHeader = "Ontologies";
                        }
                        var table = $('<table id="recommendations" class="zebra" border="1" style="display: inline-block; padding:0px" ></table>'); //create table
                        var header = $("<tr><th>POS.</th>"
                        + "<th>" + ontologyHeader +"</th>"
                        + "<th>Final score</th>"
                        + "<th>Coverage <br>score</th>"
                        + "<th>Acceptance <br>score</th>"
                        + "<th>Detail <br>score</th>"
                        + "<th>Specialization <br>score</th>"
                        + "<th>Annotations</th>"
                        + "<th>Highlight <br>annotations</th>"
                        + "</th>");
                        table.append(header);

                        for (var i = 0; i < data.length; i++) {
                            var position = i + 1;
                            // Terms covered
                            var terms = '';
                            for (var j = 0; j < data[i].coverageResult.annotations.length; j++) {
                                terms += ('<a target="_blank" href=' + data[i].coverageResult.annotations[j].annotatedClass.links.ui + '>' + data[i].coverageResult.annotations[j].text + '</a>, ');
                            }
                            // Remove last comma and white
                            terms = terms.substring(0, terms.length - 2);

                            var finalScore = data[i].evaluationScore * 100;
                            var coverageScore = data[i].coverageResult.normalizedScore * 100;
                            var acceptanceScore = data[i].acceptanceResult.normalizedScore * 100;
                            var detailScore = data[i].detailResult.normalizedScore * 100;
                            var specializationScore = data[i].specializationResult.normalizedScore * 100;

                            var row = '<tr class="row"><td>' + position + '</td><td>';

                            $.each(data[i].ontologies, function (j, item) {
                                var ontologyLinkStyle = 1
                                if (params.output_type == 2) {
                                    ontologyLinkStyle = 'style="color: ' + rec.colors[j] + '"';
                                }
                                row += '<a ' + ontologyLinkStyle + /*'title= "' + data[i].ontologies[j].name +*/ '" target="_blank" href=' + data[i].ontologies[j].links.ui + '>'
                                + data[i].ontologies[j].acronym + '</a><br />'});

                            row += "</td>";
                            row += '<td><div style="width:120px"><div style="text-align:left;width:' + finalScore.toFixed(0) + '%;color:#ccc;background-color:#76A7CC;border-style:solid;border-width:1px;border-color:#76A7CC">' + finalScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td><div style="width:120px"><div style="text-align:left;width:' + coverageScore.toFixed(0) + '%;background-color:#8cabd6;border-style:solid;border-width:1px;border-color:#3e76b6">' + coverageScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td><div style="width:120px"><div style="text-align:left;width:' + acceptanceScore.toFixed(0) + '%;background-color:#8cabd6;border-style:solid;border-width:1px;border-color:#3e76b6">' + acceptanceScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td><div style="width:120px"><div style="text-align:left;width:' + detailScore.toFixed(0) + '%;background-color:#8cabd6;border-style:solid;border-width:1px;border-color:#3e76b6">' + detailScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td><div style="width:120px"><div style="text-align:left;width:' + specializationScore.toFixed(0) + '%;background-color:#8cabd6;border-style:solid;border-width:1px;border-color:#3e76b6">' + specializationScore.toFixed(1) + '</div></div>' + '</td>'
                            + '<td>' + data[i].coverageResult.annotations.length + '</td>'
                            + '<td>' + '<div style="text-align:center"><input style="vertical-align:middle" id="chk' + i + '" type="checkbox"/></div>'
                            + '</tr>';
                            table.append(row); // Append row to table
                        }
                        $("#results").append(table); // Append table to your dom wherever you want

                        // Hide get recommentations button
                        $("#recommenderButton").hide();
                        // Show edit button
                        $("#editButton").show();

                        // Check first checkbox and highlight annotations
                        rec.checkFirst(data);

                        // Checkboxes listeners
                        for (var i = 0; i < data.length; i++) {
                            $("#chk" + i).click( function(){
                                var $this = $(this);
                                var $rowNumber = $this.attr("id").substring(3);
                                if ($this.is(':checked')) {
                                    // Deselect all the rest checkboxes
                                    for (var j = 0; j < data.length; j++) {
                                        if (j!=$rowNumber) {
                                            $("#chk" + j).prop('checked', false);
                                            $("#chk" + j).parents(".row:first").css("background-color", "white");
                                        }
                                    }
                                    // Terms covered
                                    var terms = rec.getHighlightedTerms(data, $rowNumber);
                                    $("#inputTextHighlighted").empty();
                                    $("#inputTextHighlighted").append(terms);
                                    $("#inputTextHighlighted").show();
                                    $(this).parents(".row:first").css("background-color", "#e2ebf0");
                                }
                                // Avoids to uncheck the selected row
                                else {
                                    $this.prop('checked', true);
                                }
                            });
                        }
                        // Edit input
                        $("#editButton").click( function(){
                            rec.enableEdition()
                        });
                    }
                    else { // No results
                        if ($("#radioOtSets").is(":checked"))
                            $("#noResultsSets").show();
                        else
                            $("#noResults").show();
                    }
                }
            },
            error: function(errorData) {
                $(".recommenderSpinner").hide();
                $(".generalError").show();
                console.log("error", errorData);
            }
        });
    }
}

// Check first checkbox and highlight annotations
rec.checkFirst = function(data) {
    var terms = rec.getHighlightedTerms(data, 0);
    $("#chk0").prop("checked", true);
    $("#inputText").hide();
    $("#inputTextHighlighted").empty();
    $("#inputTextHighlighted").append(terms);
    $("#inputTextHighlighted").show();
    $("#chk0").parents(".row:first").css("background-color", "#e2ebf0");
}

jQuery(document).ready(function() {
    // Abort it not right page
    var path = currentPathArray();
    if (path[0] !== "recommender") {
      return;
    }

    rec.emptyInput = true;
    $("#recommenderButton").click(rec.getRecommendations);
    $("#insertInputLink").click(rec.insertInput);
    $("input[name=input_type]:radio").change(function () {
        rec.enableEdition()});
    $("input[name=output_type]:radio").change(function () {
        rec.enableEdition()});
    $("#ontologyPicker").click(rec.enableEdition);
    $("#input_wc").click(rec.enableEdition);
    $("#input_wa").click(rec.enableEdition);
    $("#input_wd").click(rec.enableEdition);
    $("#input_ws").click(rec.enableEdition);
    $("#input_max_ontologies").click(rec.enableEdition);
    $("#input_wc").focus(rec.enableEdition);
    $("#input_wa").focus(rec.enableEdition);
    $("#input_wd").focus(rec.enableEdition);
    $("#input_ws").focus(rec.enableEdition);
    $("#input_max_ontologies").focus(rec.enableEdition);
    $("#inputText").click(rec.prepareForRealInput);
    $("#advancedOptionsLink").click(rec.showOrHideAdvancedOptions);
    $("#advancedOptions").hide();
    $(".recommenderSpinner").hide();
    $("#editButton").hide();
    rec.hideErrorMessages();
});
