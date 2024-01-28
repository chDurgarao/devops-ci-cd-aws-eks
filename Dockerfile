FROM openjdk:8
ADD jarstaging/com/dj/demo-workshop/2.1.5/demo-workshop-2.1.5.jar project.jar
ENTRYPOINT [ "java", "-jar", "project.jar" ]