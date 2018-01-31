# EAF2Transcript
xslt 1.0 compatible conversion of ELAN EAF file in a form more like a transcript.

## Purpose:
EAF is a format suitable for serialization of transcript data. It defines multiple "tiers" of annotation which can be arranged by types which define the relationship between annotations on tiers. As stored in EAF, each tier is a flat listing of annotations within a tier. This xsl transforms this into a nested annotations. In elan these nested annoations are called "annotation groups".

A regular transcript is usually either a top-to-bottom listing of these annotation groups, or a timeline of these groups. For a timeline, annotation groups are usually offset horizontally by time, and vertically by speaker.*

## Organisation:

### Tiers:
Each tier is a string of one or more annotations. A tier has a name, type and speaker label. Very commonly the name of a tier may be the concatenation of the type and the speaker label. For this reason, and because the speaker label is not required, it is sometimes left blank.
