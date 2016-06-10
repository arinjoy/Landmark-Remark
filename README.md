# Landmark-Remark
A simple iOS app to let the users save landmarks at their current locations and add note to that. Users can search for landmarks created by them and also by other users.

The explicit requirements are:  
1.	As a user (of the application) I can see my current location on a map  
2.	As a user I can save a short note at my current location  
3.	As a user I can see notes that I have saved at the location they were saved on the map  
4.	As a user I can see the location, text, and user­name of notes other users have saved  
5.	As a user I have the ability to search for a note based on contained text or user­name  


## Approach to the solution:

From the above explicit requirements/ functionalities the following implicit requirements are recognised.
-	To be able allow for multiple app users, backend persistence with a server is necessary
-	A user should be able register/signup with the app
-	A user can login/logout to/from the app
-	A user should be logged-in automatically as soon as the app is launched unless they have logged-out deliberately
-	The app should constantly update current user location using GPS
-	A user should be able to see his current location with a special indicator/icon on the map
-	A user should be able to see the change in the in his location animated within the map
-	A user should be able to see all the landmarks (either created by him or other users) around his current location
-	A user should be able to easily identify a landmark whether its created by him or other user
-	A user should be able to search for landmark easily and also make apply filter to either select his own landmarks or created by others, or all landmarks
-	A user should be able tap on the landmark pin on the map and see the details (note/remark and the username)
-	A user should be able to make some simple actions on the landmark, such as, open up the Apple’s Maps app to get driving direction to that location
-	If the user is a creator of the landmark, he should be able to update the note to make some alterations/change, fixing typo etc.
-	If the user is a creator of a landmark, he should be able to delete the landmark permanently if he thinks it’s not relevant anymore or inadvertently created, or some other reasons
-	User should be able to zoom-in/zoom out the map to look for landmarks, but by default nearest landmarks are shown first than the farthest ones
-	User should be able to see the list of all landmarks in a list to be able to scroll easily because looking for multiple landmarks within a small region can be quite hard to zoom-in sometimes
-	Users might need to set the boundary preference for the search results. For example, they may not be bothered to see the landmarks which are too far from them or in a different country for instance
-	Users should be able to refresh the list of landmarks from the internet with some sort of control because the app has a real-time aspect of multiple users creating many landmarks at the same time


## 1. Architecture:

This app has deigned using well-known Model-View-ViewModel (MVVM) pattern to provide loose coupling between separate layers and provide a clear separation of concerns between them. It is also useful for maintainability and it also avoids the Massive-View controllers problem.

Typically the project structure has the followings:  
1.	Services – The core of the app that talks to the backend side via network calls and provide interface for CRUD operations, and also includes the authentication related services  
2.	Models – The data model to represent an entity. eg. Landmark  
3.	View-Models – The model representing the data necessary for the view to display itself; but it’s also responsible for gathering, interpreting, and transforming that data by communicating with services layer  
4.	View-Controllers – The controllers that directly interact with the UI and manage the UI state. The code for Views and View-Controllers have similar goals and they are commonly categorised into one category  

The communication between view-models and view-controllers can happen in many different ways - delegates, callback blocks, notifications, KVO, target/action event observers. Each of this approach has its own pros and cons. My personal preference is to use ReactiveCocoa to handle them in a clean and efficient way. However, due to strict requirements of this assignment for not to use any non-apple library/framework, I refrained from using ReactiveCocoa. I have chosen traditional delegate based approach to achieve the communication between view-models and view-controllers. 

