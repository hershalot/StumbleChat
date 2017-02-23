# WoolyBear (initially called StumbleChat)
Randomly pair with another user and chat - IOS

A basic chat matching application using Firebase. 

On search, user is tossed into one of two pools, aggressive and passive. If the pools are the same size, user will default to 
the passive pool. Otherwise they are thrown into the aggressive pool and will actively look for a user in the passive pool. 

The passive pool uses a First in First out Queue.

All chat data is removed from Firebase when the conversation is closed (Except photos since there isn't a recursive delete option for Firebase Storage yet - 2/20/2017). Photos are deleted Daily.

Next TODO: Add bounce Animations on swipe navigations.

Uses Pods:
JSQMessagesController for the chat ViewController,
EAIntroView for the IntroView on start,
Firebase/Core, 
Firebase/Auth (Anon),
Firebase/Database, 
Firebase/Storage -- for picture messages

Feel free to edit or modify code, provide suggestions. 
