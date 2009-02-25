<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template match="resources">
<html><head></head><body>
<h1>Llista de recursos</h1>

<table style="border-spacing:1em; border:1px solid black;">
<thead><tr><th>Descripció</th><th>Granularitat</th></tr></thead>
<tbody>
<xsl:apply-templates select="resource"/>
</tbody>
</table>
<hr/>
<a href="#">[Crear un nou recurs]</a>
</body></html>
</xsl:template>


<xsl:template match="resource">
    <tr>
        <td><xsl:value-of select="description"/></td>
        <td><xsl:value-of select="granularity"/></td>
        <td><a href="#">Modifica</a> | <a href="#">Reserva</a> | <a href="#">Esborra</a></td>
    </tr>
</xsl:template>

</xsl:stylesheet>

