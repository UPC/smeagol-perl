<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xlink="http://www.w3.org/1999/xlink">
<xsl:template match="resources">
<html><head></head><body>
<h1>Llista de recursos</h1>

<table style="border-spacing:1em">
<thead><tr><th>Id</th><th>Descripció</th><th></th></tr></thead>
<tbody>
<xsl:apply-templates select="resource">
    <xsl:sort select="substring-after(@xlink:href, '/resource/')" data-type="number" />
</xsl:apply-templates>
</tbody>
</table>
<hr/>
Sméagol v0.1rc1
</body></html>
</xsl:template>

<xsl:template match="resource">
        <tr>
        <td><xsl:value-of select="substring-after(@xlink:href, '/resource/')"/></td>
        <td><xsl:value-of select="description"/></td>
        <td><a href="{@xlink:href}">Detalls</a></td>
        </tr>
</xsl:template>

</xsl:stylesheet>

