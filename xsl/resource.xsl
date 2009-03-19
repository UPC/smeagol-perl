<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xlink="http://www.w3.org/1999/xlink">
<xsl:template match="resource">
<html><head></head><body>
<h1>Dades del recurs #<xsl:value-of select="substring-after(@xlink:href, 'resource/')"/></h1>

<h2>Característiques</h2>
<dl>
<dt style="margin:1em">Descripció:</dt><dd><xsl:value-of select="description"/></dd>
<dt style="margin:1em">Granularitat:</dt><dd><xsl:value-of select="granularity"/></dd>
</dl>

<h2>Reserves</h2>
<table style="border-spacing: 1em">
<thead><tr><th>ID</th><th>Descripció</th><th>Inici</th><th>Fi</th></tr></thead>
<tbody>
<xsl:apply-templates select="agenda"/>
</tbody>
</table>

<hr/>
<a href="/resources">[Llista de recursos]</a> | 
<a><xsl:attribute name="href"><xsl:value-of select="concat(@xlink:href, '/bookings')"/></xsl:attribute>[Agenda del recurs]</a>
</body></html>
</xsl:template>


<xsl:template match="agenda">
    <xsl:apply-templates/>
</xsl:template>

<xsl:template match="booking">
<tr>
    <td><xsl:value-of select="id"/></td>
    <td><tt><xsl:apply-templates select="description"/></tt></td>
    <td><tt><xsl:apply-templates select="from"/></tt></td>
    <td><tt><xsl:apply-templates select="to"/></tt></td>
</tr>
</xsl:template>


<xsl:template match="from|to">
<xsl:value-of select="year"/>-<xsl:value-of select="month"/>-<xsl:value-of select="day"/>
a les
<xsl:value-of select="hour"/>:<xsl:value-of select="minute"/> h
</xsl:template>

</xsl:stylesheet>

