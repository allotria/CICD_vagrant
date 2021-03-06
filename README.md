#Kompetensdag CI/CD dag 1

##Förberedelser

1. Installera git och ssh
 - Windows: https://msysgit.github.io/ Välj förvalda alternativ
 - Mac OS: Använd ‘port’ (https://www.macports.org/), ‘fink’ (http://www.finkproject.org/) eller någon annan väg
2. Gå till https://www.vagrantup.com/ och ladda ner respektive installationspaket för din dator.
3. Installera paketet och starta om datorn
4. Klona git-repot med vagrantkonfiguration och provisioneringsskript i lämplig katalog:

```$ git clone https://github.com/allotria/CICD_vagrant.git```

5. Kör vagrant up i den klonade projektkatalogen
6. Vänta (kan ta upp emot 45 min)

##Förutsättningar

Det finns tre virtuella maskiner i labben. Den första, ci/cd-maskinen, innehåller Jenkins, Sonar och de två git-repona med labbens testapplikationer. Vidare finns två maskiner, test och prod, som simulerar en test- respektive produktionsmiljö.

Man kan nå maskinerna m.h.a. ```vagrant ssh <maskinens vagrantnamn>```
###CI/CD-maskin

####Allmänt:
 - OS: Ubuntu 14.04.1 LTS (Trusty Tahr)
 - IP: 192.168.33.10
 - Vagrantnamn: ci
 - Minne: 2 GB
 - Java: Oracle JDK 8

####Jenkins:
http://192.168.33.10:8080

####Nexus:
http://192.168.33.10:8081/nexus

user: admin 
password: admin123

####Sonar:
http://192.168.33.10:8083

user: admin 
password: admin

####Git:
På din host-dator:

```$ ssh-add keys/id_rsa```

```$ git clone git@192.168.33.10:cicd-lab-backend.git```

```$ git clone git@192.168.33.10:ci-frontendApp.git```

Om du kör windows:
Öppna git bash och kör följande

```$ eval $(ssh-agent)```

```$ ssh-add keys/id_rsa```

```$ git clone git@192.168.33.10:cicd-lab-backend.git```

```$ git clone git@192.168.33.10:ci-frontendApp.git```

###TEST-maskin

####Allmänt:
 - OS: Ubuntu 14.04.1 LTS (Trusty Tahr)
 - IP: 192.168.33.20
 - Vagrantnamn: test
 - Minne: 512 MB
 - Java: Oracle JDK 8
 - Apache webserver
 - Jetty 8 (/usr/share/jetty8)

###PROD-maskin

####Allmänt:
 - OS: Ubuntu 14.04.1 LTS (Trusty Tahr)
 - IP: 192.168.33.30
 - Vagrantnamn: prod
 - Minne: 512 MB
 - Java: Oracle JDK 8
 - Apache webserver
 - Jetty 8 (/usr/share/jetty8)

###Backendapplikationen

Backendapplikationen är skriven i Java, använder sig utav Spring boot och har ett par enhetstester.
Gitrepo: git@192.168.33.10:cicd-lab-backend.git

 - Bygg:
 
```$ mvn clean package```

 - Packa upp tar.gz:en i lämplig katalog t.ex.:
 
```$ tar xzvf target/cicd-lab-backend-1.0-bin.tar.gz -C ~```

 - Starta applikationen:
 
```$ cd ~/cicd-lab-backend-1.0 && ./application.sh start```

 - application.sh-skriptet kan bl.a. starta, stoppa och visa status:
 
```$ ./application.sh [start|stop|restart|debug|status]```

###Frontendapplikationen

Frontendapplikationen är byggd m.h.a. AngularJs och innehåller även ett par enhetstester. På både test- och prodmaskinen finns det en Apache webserver som kan användas när frontendapplikationen ska deployas.

Gitrepo: git@192.168.33.10:ci-frontendApp.git

 - Installera först node, sedan:
 
```$ npm install -g grunt-cli```

```$ npm install -g bower```

 - Köra applikationen: 
 
```$ grunt serve```

 - Köra tester: 
 
```$ grunt test```

 - Bygga applikationen:
  
```$ grunt build --url=hostname```

##Målbild

Målet med labben är att sätta upp två fungerande byggpipelines: för backend- respektive frontendapplikationen som finns i ci-maskinens två gitrepon. Byggpipelinerna ska bygga, testa och deploya applikationen till test-miljön automatiskt och ett bygge ska triggas på push till applikationens gitrepo. Byggpipelinerna görs lämpligtvis som en serie kedjade Jenkinsjobb och kan visualiseras m.h.a. Jenkins Build Pipeline-plugin. Ett sista manuellt triggat steg ska kunna deploya ett bygge till produktionsmiljön. Om en push till gitrepot innehåller enhetstester som inte är gröna ska bygget fallera.

##Stretch goals

På ci-maskinen finns det en sonarserver som kan användas för att lägga till ett byggsteg som granskar en applikations kodkvalitet. Mer information om Sonar och hur man kan integrera Sonar med Jenkins finns här: http://docs.sonarqube.org/display/SONAR/Documentation.

För att få bättre spårbarhet och kontroll över vilka byggen som är okej att tas till produktion kan man använda sig utav Jenkins Promoted Builds Plugin: https://wiki.jenkins-ci.org/display/JENKINS/Promoted+Builds+Plugin

Ett tänkbart flöde när man använder denna plugin kan vara att skapa ett jenkinsjobb som utför promote-logik, t.e.x gör en secure copy till produktionsmiljö. Jobbet tar som inparametrar ett jobbnamn och byggnummer, så att artefakter från det jobb som triggat promotion kan användas vid deploy.
För att kunna skicka in parametrarna till promotejobb väljer man predefined parameters under Trigger/call builds on other projects. Ange sedan:

Jobb=$PROMOTED_JOB_NAME
Byggval=<SpecificBuildSelector><buildNumber>$PROMOTED_NUMBER</buildNumber></SpecificBuildSelector>

Du måste också ange att jobbet som triggar en promotion arkiverar sina artefakter så att promote-jobbet kan få tillgång till dessa.
