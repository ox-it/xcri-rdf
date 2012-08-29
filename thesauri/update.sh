#!/bin/bash

( cd attendancePattern ;
  curl http://xcri.co.uk/vocabularies/attendancePattern2_1.xml > attendancePattern.vdex ;
  saxon attendancePattern.vdex ../skosify-vdex.xsl > attendancePattern.rdf )

( cd attendanceMode ;
  curl http://xcri.co.uk/vocabularies/attendanceMode2_1.xml > attendanceMode.vdex ;
  saxon attendanceMode.vdex ../skosify-vdex.xsl > attendanceMode.rdf )

( cd studyMode ;
  curl http://xcri.co.uk/vocabularies/studyMode2_1.xml > studyMode.vdex ;
  saxon studyMode.vdex ../skosify-vdex.xsl > studyMode.rdf )

( cd vitaeRDF ;
  make all )

( cd oxRDF ;
  make all )

