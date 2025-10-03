<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="1.0">

  <!-- Output -->
  <xsl:output encoding="UTF-8" method="xml" indent="yes"/>

  <!-- Params -->
  <!-- Tiers are primarily sorted by type. Reorder to define overall sort order -->
  <xsl:param name="type_sort">Symbolic_Subdivision,Time_Subdivision,Symbolic_Association,Included_In</xsl:param>
  <!-- Secondary sort idea (kept commented) -->
  <!-- <xsl:param name="meta_type_sort">morpheme,mf,gloss,mg,pos,partofspeech,wordclass</xsl:param> -->

  <!-- Keys -->
  <xsl:key name="tsById"        match="TIME_ORDER/TIME_SLOT" use="@TIME_SLOT_ID"/>
  <xsl:key name="lingById"      match="LINGUISTIC_TYPE"      use="@LINGUISTIC_TYPE_ID"/>
  <xsl:key name="tierById"      match="TIER"                 use="@TIER_ID"/>
  <xsl:key name="tiersByParent" match="TIER[@PARENT_REF]"    use="@PARENT_REF"/>
  <xsl:key name="refByPrev"     match="REF_ANNOTATION"       use="@PREVIOUS_ANNOTATION"/>
  <xsl:key name="refByTarget"   match="REF_ANNOTATION"       use="@ANNOTATION_REF"/>

  <!-- Identity -->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- Root transform -->
  <xsl:template match="/ANNOTATION_DOCUMENT">
    <xsl:processing-instruction name="xml-stylesheet">href="SimpleEAF.css" type="text/css"</xsl:processing-instruction>
    <transcript>
      <header>
        <!-- keep HEADER content by default copy -->
        <xsl:apply-templates select="HEADER"/>
      </header>

      <!-- Top-level turns: non-child tiers' alignable annotations, sorted by real time -->
      <xsl:apply-templates select="TIER[not(@PARENT_REF)]/ANNOTATION/ALIGNABLE_ANNOTATION">
        <xsl:sort data-type="number" order="ascending"
                  select="number(key('tsById', @TIME_SLOT_REF1)/@TIME_VALUE)"/>
        <xsl:with-param name="class">annotations</xsl:with-param>
      </xsl:apply-templates>
    </transcript>
  </xsl:template>

  <!-- Convert time slot references to begin/end using keys -->
  <xsl:template match="@TIME_SLOT_REF1">
    <xsl:attribute name="begin">
      <xsl:value-of select="key('tsById', .)/@TIME_VALUE"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="@TIME_SLOT_REF2">
    <xsl:attribute name="end">
      <xsl:value-of select="key('tsById', .)/@TIME_VALUE"/>
    </xsl:attribute>
  </xsl:template>

  <!-- Render annotation value as a block -->
  <xsl:template match="ANNOTATION_VALUE">
    <block><xsl:value-of select="."/></block>
  </xsl:template>

  <!-- Render annotations and descend into child tiers -->
  <xsl:template match="REF_ANNOTATION | ALIGNABLE_ANNOTATION">
    <xsl:param name="supress_parent_attributes">false</xsl:param>
    <xsl:param name="class"/>
    <xsl:element name="{$class}">
      <xsl:if test="$supress_parent_attributes = 'false'">
        <xsl:apply-templates select="../../@*"/>
      </xsl:if>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="ANNOTATION_VALUE"/>

      <!-- Child tiers of the current tier -->
      <xsl:variable name="parentTierId" select="../../@TIER_ID"/>

      <xsl:apply-templates select="key('tiersByParent', $parentTierId)">
        <!-- Sort: first by whether type is known in $type_sort, then by index within it -->
        <xsl:sort select="not(contains(concat(',', $type_sort, ','),
                                       concat(',', key('lingById', @LINGUISTIC_TYPE_REF)/@CONSTRAINTS, ',')))"
                  data-type="text" order="ascending"/>
        <xsl:sort data-type="number" order="ascending"
                  select="string-length(substring-before(concat($type_sort, ','),
                                                        concat(key('lingById', @LINGUISTIC_TYPE_REF)/@CONSTRAINTS, ',')))"/>
        <xsl:with-param name="parent_ann" select="."/>
      </xsl:apply-templates>
    </xsl:element>

    <!-- Symbolic_Subdivision chaining via key, not // -->
    <xsl:apply-templates select="key('refByPrev', @ANNOTATION_ID)">
      <xsl:with-param name="supress_parent_attributes">true</xsl:with-param>
      <xsl:with-param name="class">span</xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <!-- TIER rendering -->
  <xsl:template match="TIER">
    <xsl:param name="parent_ann"/>

    <xsl:choose>
      <!-- Symbolic_Association: children that explicitly reference parent annotation -->
      <xsl:when test="key('lingById', @LINGUISTIC_TYPE_REF)/@CONSTRAINTS = 'Symbolic_Association'">
        <xsl:apply-templates select="ANNOTATION/REF_ANNOTATION[@ANNOTATION_REF=$parent_ann/@ANNOTATION_ID]">
          <xsl:with-param name="class">block</xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>

      <!-- Other stereotypes: time-contained alignables plus symbolic subdivision chains -->
      <xsl:otherwise>
        <xsl:element name="block">
          <xsl:apply-templates select="@*"/>

          <!-- Start of symbolic subdivision chain -->
          <xsl:apply-templates
              select="ANNOTATION/REF_ANNOTATION[@ANNOTATION_REF=$parent_ann/@ANNOTATION_ID][not(@PREVIOUS_ANNOTATION)]">
            <xsl:with-param name="supress_parent_attributes">true</xsl:with-param>
            <xsl:with-param name="class">span</xsl:with-param>
          </xsl:apply-templates>

          <!-- Alignable annotations whose times are contained within the parent annotation -->
          <xsl:apply-templates
              select="ANNOTATION/ALIGNABLE_ANNOTATION
                        [ number(key('tsById', $parent_ann/@TIME_SLOT_REF1)/@TIME_VALUE)
                          &lt;= number(key('tsById', @TIME_SLOT_REF1)/@TIME_VALUE)
                          and
                          number(key('tsById', @TIME_SLOT_REF2)/@TIME_VALUE)
                          &lt;= number(key('tsById', $parent_ann/@TIME_SLOT_REF2)/@TIME_VALUE) ]">
            <xsl:sort data-type="number" order="ascending"
                      select="number(key('tsById', @TIME_SLOT_REF1)/@TIME_VALUE)"/>
            <xsl:with-param name="supress_parent_attributes">true</xsl:with-param>
            <xsl:with-param name="class">span</xsl:with-param>
          </xsl:apply-templates>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Attribute rewrites -->

  <xsl:template match="@LINGUISTIC_TYPE_REF">
    <xsl:attribute name="type">
      <xsl:value-of select="."/>
    </xsl:attribute>
    <xsl:if test="key('lingById', .)/@CONSTRAINTS">
      <xsl:attribute name="stereotype">
        <xsl:value-of select="key('lingById', .)/@CONSTRAINTS"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@TIER_ID">
    <xsl:attribute name="tier_name">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="@PARTICIPANT">
    <!-- parent participant for reference -->
    <xsl:attribute name="parent_participant">
      <xsl:value-of select="key('tierById', ../@PARENT_REF)/@PARTICIPANT"/>
    </xsl:attribute>
    <xsl:attribute name="participant">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>

  <!-- Suppress unneeded elements/attributes -->
  <xsl:template match="TIME_ORDER | LINGUISTIC_TYPE | CONSTRAINT | @PARENT_REF | @ANNOTATION_REF | @PREVIOUS_ANNOTATION | @ANNOTATION_ID"/>

</xsl:stylesheet>
