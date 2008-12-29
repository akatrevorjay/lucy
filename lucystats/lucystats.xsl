<?xml version="1.0"?>
<!--
	Lucy; irc bot
	~trevorj <[trevorjoynson@gmail.com]>

	Copyright 2006 Trevor Joynson

	This file is part of Lucy.

	Lucy is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.
	
	Lucy is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with Lucy; if not, write to the Free Software
	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
-->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:template match="/">
<html>
<body>
<h2>LucyStats version 0.4 [timestamp=<xsl:value-of select="lucystats/ts"/>]</h2>
Mmmmmmm...<br />
<br />
	<table>
	<tr>
		<th>Id</th>
		<th>Name</th>
		<th>Comment</th>
		<th>ConnectTime</th>
		<th>Online?</th>
		<th>LastSplit</th>
		<th>Uptime</th>
		<th>CurrentUsers</th>
		<th>LinkedTo</th>
		<th>Hops</th>
	</tr>
	<xsl:for-each select="lucystats/link">
	<tr>
		<td><xsl:value-of select="@servid"/></td>
		<td><xsl:value-of select="@server"/></td>
		<td><xsl:value-of select="@comment"/></td>
		<td><xsl:value-of select="@connecttime"/></td>
		<td><xsl:value-of select="@online"/></td>
		<td><xsl:value-of select="@lastsplit"/></td>
		<td><xsl:value-of select="@uptime"/></td>
		<td><xsl:value-of select="@currentusers"/></td>
		<td><xsl:value-of select="@linkedto"/></td>
		<td><xsl:value-of select="@hops"/></td>
	</tr>
	</xsl:for-each>
</table>
<br />
<xsl:for-each select="lucystats/channel">
<h3>Users on <xsl:value-of select="@name"/></h3>
<table>
	<tr>
		<th>Nick</th>
		<th>Seen</th>
		<th>SeenTimestamp</th>
		<th>ConnectTime</th>
		<th>Country</th>
		<th>Away?</th>
		<th>IrcOp?</th>
	</tr>
	<xsl:for-each select="user">
	<tr>
		<td><xsl:value-of select="@nick"/></td>
		<td><xsl:value-of select="@seen"/></td>
		<td><xsl:value-of select="@ts"/></td>
		<td><xsl:value-of select="@connecttime"/></td>
		<td><xsl:value-of select="@country"/></td>
		<td><xsl:value-of select="@away"/></td>
		<td><xsl:value-of select="@mode_lo"/></td>
	</tr>
	</xsl:for-each>
</table>
</xsl:for-each>
<h3>Factoids</h3>
<table>
	<tr>
		<th>Factoid</th>
		<th>Definition</th>
		<th>Who</th>
	</tr>
	<xsl:for-each select="lucystats/factoid">
	<tr>
		<td><xsl:value-of select="@fact"/></td>
		<td><xsl:value-of select="@definition"/></td>
		<td><xsl:value-of select="@who"/></td>
		<td><xsl:value-of select="@ts"/></td>
	</tr>
	</xsl:for-each>
</table>
</body>
</html>
</xsl:template>
</xsl:stylesheet>
