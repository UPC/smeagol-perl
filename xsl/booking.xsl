<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="booking"><html><head></head><body>
<h1>Dades de la reserva #<xsl:value-of select="id"/></h1>
<table style="border: 1px solid black; border-spacing: 1em">
<tr><td><strong>Identificador:</strong></td><td><tt><xsl:value-of select="id"/></tt></td></tr>
<tr><td><strong>Inici:</strong></td><td><tt><xsl:apply-templates select="from"/></tt></td></tr>
<tr><td><strong>Fi:</strong></td><td><tt><xsl:apply-templates select="to"/></tt></td></tr>
</table>
<hr/>
<a href="/resources">[Llista de recursos]</a> | <a href="#">[Modificar la reserva]</a> | <a href="#">[Esborrar la reserva]</a>
</body></html></xsl:template>

<xsl:template match="from|to">
<xsl:value-of select="year"/>-<xsl:value-of select="month"/>-<xsl:value-of select="day"/>
a les
<xsl:value-of select="hour"/>:<xsl:value-of select="minute"/>:<xsl:value-of select="second"/>
</xsl:template>

</xsl:stylesheet>
