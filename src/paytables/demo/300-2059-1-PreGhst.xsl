<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
    <xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl"/>
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl"/>

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />
			
			<!--
			TEMPLATE
			Match:
			-->
			<x:template match="/">
				<x:apply-templates select="*"/>
				<x:apply-templates select="/output/root[position()=last()]" mode="last"/>
				<br/>
			</x:template>
			<lxslt:component prefix="my-ext" functions="formatJson retrievePrizeTable">
				<lxslt:script lang="javascript">
					<![CDATA[
var debugFeed = [];
var debugFlag = false;
// Format instant win JSON results.
// @param jsonContext String JSON results to parse and display.
// @param translation Set of Translations for the game.
function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc) {
	var scenario = getScenario(jsonContext);
	var winningNums = getWinningNumbers(scenario);
	var outcomeNums = getOutcomeData(scenario, 0);
	var outcomePrizes = getOutcomeData(scenario, 1);
	var prizeNames = (prizeNamesDesc.substring(1)).split(',');
	var convertedPrizeValues = (prizeValues.substring(1)).split('|');
	// Output winning numbers table.
	var r = [];
	r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr><td class="tablehead" colspan="' + winningNums.length + '">');
	r.push(getTranslationByName("winningNumbers", translations));
	r.push('</td></tr>');
	r.push('<tr>');
	for (var i = 0; i < winningNums.length; ++i) {
		r.push('<td class="tablebody">');
		r.push(winningNums[i]);
		r.push('</td>');
	}
	r.push('</tr>');
	r.push('</table>');
	// Output outcome numbers table.
	r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
	r.push('<tr><td class="tablehead" colspan="2">');
	r.push(getTranslationByName("yourNumbers", translations));
	r.push('</td></tr>');
	r.push('<tr>');
	r.push('<tr>');
	r.push('<td class="tablehead" width="50%">');
	r.push(getTranslationByName("boardNumbers", translations));
	r.push('</td>');
	r.push('<td class="tablehead" width="50%">');
	r.push(getTranslationByName("boardValues", translations));
	r.push('</td>');
	r.push('</tr>');
	for (var i = 0; i < outcomeNums.length; ++i) {
		r.push('<tr>');
		r.push('<td class="tablebody" width="50%">');
		if (checkMatch(winningNums, outcomeNums[i])) {
			r.push(getTranslationByName("youMatched", translations) + ': ');
		}
		r.push(outcomeNums[i]);
		r.push('</td>');
		r.push('<td class="tablebody" width="50%">');
		r.push(convertedPrizeMultiplier(outcomePrizes[i].substring(1), translations) + convertedPrizeValues[getPrizeNameIndex(prizeNames, outcomePrizes[i].charAt(0))]);
		r.push('</td>');
		r.push('</tr>');
	}
	r.push('</table>');
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// !DEBUG OUTPUT TABLE
	if (debugFlag) {
		// DEBUG TABLE
		//////////////////////////////////////
		r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
		for (var idx = 0; idx < debugFeed.length; ++idx) {
			if (debugFeed[idx] == "")
				continue;
			r.push('<tr>');
			r.push('<td class="tablebody">');
			r.push(debugFeed[idx]);
			r.push('</td>');
			r.push('</tr>');
		}
		r.push('</table>');
	}
	return r.join('');
}
function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint) {
	var pricePointList = pricePoints.split(",");
	var prizeStructStrings = prizeStructures.split("|");
	for (var i = 0; i < pricePoints.length; ++i) {
		if (wageredPricePoint == pricePointList[i]) {
			return prizeStructStrings[i];
		}
	}
	return "";
}
function getScenario(jsonContext) {
	// Parse json and retrieve scenario string.
	var jsObj = JSON.parse(jsonContext);
	var scenario = jsObj.scenario;
	// Trim null from scenario string.
	scenario = scenario.replace(/\0/g, '');
	return scenario;
}
function getPricePoint(jsonContext) {
	// Parse json and retrieve price point amount
	var jsObj = JSON.parse(jsonContext);
	var pricePoint = jsObj.amount;
	return pricePoint;
}
function getWinningNumbers(scenario) {
	var numsData = scenario.split("|")[0];
	return numsData.split(",");
}
function getOutcomeData(scenario, index) {
	var outcomeData = scenario.split("|")[1];
	var outcomePairs = outcomeData.split(",");
	var result = [];
	for (var i = 0; i < outcomePairs.length; ++i) {
		result.push(outcomePairs[i].split(":")[index]);
	}
	return result;
}
function translateOutcomeNumber(outcomeNum, translations) {
	if (outcomeNum == 'I') {
		return getTranslationByName("instantWin", translations);
	} else if (outcomeNum == 'X') {
		return getTranslationByName("instantDoubler", translations);
	} else if (outcomeNum == 'M') {
		return getTranslationByName("instantMultiplier", translations);
	} else {
		return outcomeNum;
	}
}
function checkMatch(winningNums, boardNum) {
	for (var i = 0; i < winningNums.length; ++i) {
		if (winningNums[i] == boardNum || boardNum == "I" || boardNum == "X" || boardNum == "M") {
			return true;
		}
	}
	return false;
}
function getPrizeNameIndex(prizeNames, currPrize) {
	for (var i = 0; i < prizeNames.length; ++i) {
		if (prizeNames[i] == currPrize) {
			return i;
		}
	}
}
function convertedPrizeMultiplier(multiplier, translations) {
	if (multiplier == "2") {
		return getTranslationByName("instantDoubler", translations) + " : ";
	} else if (multiplier == "5") {
		return getTranslationByName("instantMultiplier", translations) + " : ";
	} else if (multiplier == "10") {
		return getTranslationByName("instantMultiplier10x", translations) + " : ";
	} else if (multiplier == "20") {
		return getTranslationByName("instantMultiplier20x", translations) + " : ";
	}
	return "";
}
function getTranslationByName(keyName, translationNodeSet) {
	var index = 1;
	while (index < translationNodeSet.item(0).getChildNodes().getLength()) {
		var childNode = translationNodeSet.item(0).getChildNodes().item(index);
		if (childNode.name == "phrase" && childNode.getAttribute("key") == keyName) {
			return childNode.getAttribute("value");
		}
		index += 1;
	}
}
////////////////////////////////////////////////////////////////////////////////////////
function registerDebugText(debugText) {
	debugFeed.push(debugText);
}
/////////////////////////////////////////////////////////////////////////////////////////
					]]>
				</lxslt:script>
			</lxslt:component>
			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount"/>
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit"/>
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode"/>
								<x:with-param name="locale" select="//translation/@language"/>
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>
		
			<!--
			TEMPLATE
			Match:		digested/game
			-->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="History.Detail" />
				</x:if>
				<x:if test="OutcomeDetail/Stage = 'Wager' and OutcomeDetail/NextStage = 'Wager'">
					<x:call-template name="History.Detail" />
				</x:if>
			</x:template>
		
			<!--
			TEMPLATE
			Name:		Wager.Detail (base game)
			-->
			<x:template name="History.Detail">
				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value"/>
							<x:value-of select="': '"/>
							<x:value-of select="OutcomeDetail/RngTxnId"/>
						</td>
					</tr>
				</table>
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>
				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>
				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>
		
			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			
			<x:template match="text()"/>
			
		</x:stylesheet>
	</xsl:template>
	
	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
		    <clickcount>
		        <x:value-of select="."/>
		    </clickcount>
		</x:template>
		<x:template match="*|@*|text()">
		    <x:apply-templates/>
		</x:template>
	</xsl:template>
	
</xsl:stylesheet>
 