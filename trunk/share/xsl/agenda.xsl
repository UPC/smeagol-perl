<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xlink="http://www.w3.org/1999/xlink">
<xsl:template match="agenda">
<html><head></head><body>
<h1>Agenda del recurs #<xsl:value-of select="substring-before(substring-after(@xlink:href, '/resource/'), '/bookings')"/></h1>
<table style="border-spacing: 1em">
<thead><tr><th>ID reserva</th><th>Descripció</th><th>Inici</th><th>Fi</th><th></th></tr></thead>
<tbody>
<xsl:apply-templates select="booking">
    <xsl:sort select="id" data-type="number" order="ascending"/>
</xsl:apply-templates>
</tbody>
</table>
<hr/>
<a><xsl:attribute name="href"><xsl:value-of select="concat(@xlink:href, '/ical')"/></xsl:attribute>[iCalendar]</a> |
<a href="/resources">[Mostra tots els recursos]</a> | <a><xsl:attribute name="href"><xsl:value-of select="substring-before(@xlink:href,'/booking')"/></xsl:attribute>[Mostra el recurs]</a>
</body></html>
</xsl:template>


<xsl:template match="booking">
    <tr>
    <td style="text-align:center"><xsl:value-of select="id"/></td>
    <td><tt><xsl:apply-templates select="description"/></tt></td>
    <td><tt><xsl:apply-templates select="from"/></tt></td>
    <td><tt><xsl:apply-templates select="to"/></tt></td>
    <td><a><xsl:attribute name="href"><xsl:copy-of select="concat( substring-before( /agenda/@xlink:href, '/bookings'),'/booking/', id)"/></xsl:attribute>Detalls</a></td>
    </tr>
</xsl:template>


<xsl:template match="from|to">
<xsl:value-of select="year"/>-<xsl:value-of select="month"/>-<xsl:value-of select="day"/>
a les
<xsl:value-of select="hour"/>:<xsl:value-of select="minute"/>:<xsl:value-of select="second"/> h
</xsl:template>

</xsl:stylesheet>

