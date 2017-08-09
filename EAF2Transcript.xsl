<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="1.0">
    
    <xsl:output encoding="UTF-8" method="xml" indent="yes"/>

    <!-- Tiers are primarily sorted by type. Reorder the elements here to define the overall sort order -->
    <xsl:param name="type_sort">Symbolic_Subdivision,Time_Subdivision,Symbolic_Association,Included_In</xsl:param>
    <!-- An attempt at a secondary sort could be provided (but is disabled in template for REF/ALIGNABLE_ANNOTATION)
    <xsl:param name="meta_type_sort">morpheme,mf,gloss,mg,pos,partofspeech,wordclass</xsl:param>
    -->

    <xsl:template match="/ | @* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" />
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="/ANNOTATION_DOCUMENT">
        <xsl:processing-instruction name="xml-stylesheet">href="SimpleEAF.css" type="text/css"</xsl:processing-instruction>
        <transcript>
            <header>
                <xsl:apply-templates select="HEADER"/>
            </header>
            <xsl:apply-templates select="TIER[not(@PARENT_REF)]/ANNOTATION/ALIGNABLE_ANNOTATION">
                   <xsl:sort select="substring(/@TIME_SLOT_REF1,3)" data-type="number" order="ascending"/>
                    <xsl:with-param name="class">annotations</xsl:with-param>
            </xsl:apply-templates>
        </transcript>
    </xsl:template>
    
    <xsl:template match="@TIME_SLOT_REF1">
        <xsl:attribute name="begin">
            <xsl:value-of select="/ANNOTATION_DOCUMENT/TIME_ORDER/TIME_SLOT[@TIME_SLOT_ID=current()/../@TIME_SLOT_REF1]/@TIME_VALUE"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@TIME_SLOT_REF2">
        <xsl:attribute name="end">
            <xsl:value-of select="/ANNOTATION_DOCUMENT/TIME_ORDER/TIME_SLOT[@TIME_SLOT_ID=current()/../@TIME_SLOT_REF2]/@TIME_VALUE"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="ANNOTATION_VALUE">
        <block><xsl:value-of select="."/></block>
    </xsl:template>
    
    <xsl:template match="REF_ANNOTATION | ALIGNABLE_ANNOTATION">
        <xsl:param name="supress_parent_attributes">false</xsl:param>
        <xsl:param name="class"/><!-- span or block: what is the parent context for the current element-->
        <xsl:element name="{$class}">
            <xsl:if test="$supress_parent_attributes = 'false'">
                <xsl:apply-templates select="../../@*"/>
            </xsl:if>
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates select="ANNOTATION_VALUE"/>
            <xsl:apply-templates select="//TIER[@PARENT_REF=current()/../../@TIER_ID]">
                <xsl:sort data-type="number" select="string-length(substring-before($type_sort, //LINGUISTIC_TYPE[@LINGUISTIC_TYPE_ID=current()/@LINGUISTIC_TYPE_REF]/@CONSTRAINTS ))"/>
<!--            Enable sorts to do a secondary sort that attempts to sort based on the linguistic type label, 
                    and then the tier label, using the (disabled) param meta_type_sort
                <xsl:sort data-type="number" select="string-length(substring-before($meta_type_sort,translate(//LINGUISTIC_TYPE[@LINGUISTIC_TYPE_ID=current()/@LINGUISTIC_TYPE_REF]/@LINGUISTIC_TYPE_ID,'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')))"/>
                    This sort would be more robust if the speaker label was removed from the tier name before matching,
                    as many people use "@speaker" or "SPEAKER_" for interacting with toolbox/Flex
                <xsl:sort data-type="number" select="string-length(substring-before($meta_type_sort,translate(@TIER_ID,'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')))"/>
-->                
                <xsl:with-param name="parent_ann" select="."/>
            </xsl:apply-templates>
        </xsl:element>
        <!-- the following only applies to symbolic subdivisions -->
        <xsl:apply-templates select="//REF_ANNOTATION[@PREVIOUS_ANNOTATION=current()/@ANNOTATION_ID]">
            <xsl:with-param name="supress_parent_attributes">true</xsl:with-param>
            <xsl:with-param name="class">span</xsl:with-param>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="TIER">
        <xsl:param name="parent_ann"/>
        <xsl:choose>
            <xsl:when test="//LINGUISTIC_TYPE[@LINGUISTIC_TYPE_ID=current()/@LINGUISTIC_TYPE_REF]/@CONSTRAINTS = 'Symbolic_Association'">
                <xsl:apply-templates select="ANNOTATION/REF_ANNOTATION[@ANNOTATION_REF=$parent_ann/@ANNOTATION_ID]">
                    <xsl:with-param name="class">block</xsl:with-param>
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:element name="block">
                    <xsl:apply-templates select="@*"/>
                    <!-- a bit confusing, but go to first of sequence of symbolic subdivision, and then go across from within ref_annotation template! -->
                    <xsl:apply-templates select="ANNOTATION/REF_ANNOTATION[@ANNOTATION_REF=$parent_ann/@ANNOTATION_ID][not(@PREVIOUS_ANNOTATION)]">
                        <xsl:with-param name="supress_parent_attributes">true</xsl:with-param>
                        <xsl:with-param name="class">span</xsl:with-param>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="ANNOTATION/ALIGNABLE_ANNOTATION[substring($parent_ann/@TIME_SLOT_REF1,3)
                                                                                    &lt;=
                                                                                 substring(current()/@TIME_SLOT_REF1,3)
                                                                                    &lt;= 
                                                                                 substring($parent_ann/@TIME_SLOT_REF2,3)]">
                        <xsl:sort select="substring(ALIGNABLE_ANNOTATION/@TIME_SLOT_REF1,3)" data-type="number" order="ascending"/>
                        <xsl:with-param name="supress_parent_attributes">true</xsl:with-param>
                        <xsl:with-param name="class">span</xsl:with-param>
                    </xsl:apply-templates>
                </xsl:element>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="@LINGUISTIC_TYPE_REF">
        <xsl:attribute name="type">
            <xsl:value-of select="."/>
        </xsl:attribute>
        <xsl:if test="//LINGUISTIC_TYPE[@LINGUISTIC_TYPE_ID=current()]/@CONSTRAINTS">
            <xsl:attribute name="stereotype">
                <xsl:value-of select="//LINGUISTIC_TYPE[@LINGUISTIC_TYPE_ID=current()]/@CONSTRAINTS"/>
            </xsl:attribute>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="@TIER_ID">
        <xsl:attribute name="tier_name">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="@PARTICIPANT">
<!--        suppress participant label if parent tier has the same participant -->
        <xsl:attribute name="parent_participant">
            <xsl:value-of select="//TIER[@TIER_ID = current()/../@PARENT_REF]/@PARTICIPANT"/>
        </xsl:attribute>
        
        <xsl:attribute name="participant">
            <xsl:value-of select="."/>
        </xsl:attribute>
    </xsl:template>
    
<!--    suppress the following in output (unless otherwise handled): -->
    <xsl:template match="TIME_ORDER | HEADER | LINGUISTIC_TYPE | CONSTRAINT | @PARENT_REF | @ANNOTATION_REF | @PREVIOUS_ANNOTATION | @ANNOTATION_ID"></xsl:template>

</xsl:stylesheet>