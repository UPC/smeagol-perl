<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xlink="http://www.w3.org/1999/xlink">
<xsl:template match="tags">
<html><head></head><body>
<h1>Etiquetes del recurs #<xsl:value-of select="substring-before(substring-after(@xlink:href, '/resource/'), '/tags')"/></h1>
<ul>
<xsl:apply-templates select="tag"/>
</ul>
<hr/>
<a href="/resources">[Mostra tots els recursos]</a> | <a><xsl:attribute name="href"><xsl:value-of select="substring-before(@xlink:href,'/tags')"/></xsl:attribute>[Mostra el recurs]</a>
</body></html>
</xsl:template>

<xsl:template match="tag">
    <li><xsl:apply-templates/></li>
</xsl:template>

</xsl:stylesheet>

