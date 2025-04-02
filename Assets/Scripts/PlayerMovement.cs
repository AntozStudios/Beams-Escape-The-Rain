using System.Collections;
using UnityEngine;
using TMPro;
using System.Numerics;
using Vector2 = UnityEngine.Vector2;
using Vector3 = UnityEngine.Vector3;
using Quaternion = UnityEngine.Quaternion;

public class PlayerMovement : MonoBehaviour
{

    public int xCounter;
    public int zCounter;
    private Vector2 firstTouch, lastTouch; // Touch-Positionen
    public bool canMove;
    



    public GameObject[] hideObjectWhenGameStarts;

    
[SerializeField] TMP_Text levelCounter;    

    [SerializeField] SoundManager soundManager;

    [SerializeField] LevelManager levelManager;

  //  bool gameStarted;



[HideInInspector]public float timeToMoveCounter;
public float timeToMoveMax;


[HideInInspector]public float startAfkCounter;
[HideInInspector]public float startAfkMax ;

public bool playerHasToMove;

public bool canLeftSwipe,canRightSwipe,canDownSwipe,canUpSwipe;

[HideInInspector]public enum LastSwipe{

IDLE,
LEFT,
RIGHT,
DOWN,
UP


}

public LastSwipe lastSwipe;

public bool startAFKTimer;
    public float speed;

    void Awake(){
    startAfkCounter = startAfkMax;
   
}
    void Start()
    {
    
    }

   void Update()
{
    hideGameObjects(!levelManager.gameStarted);
    levelCounter.gameObject.SetActive(levelManager.gameStarted);

    if (canMove)
    {
        HandleKeyboard();
        HandleTouchInput();
    }

    updatePlayerHasToMove();
}


    void HandleKeyboard()
    {
        
 if (Input.GetKeyUp(KeyCode.LeftArrow))
        {
           if(canLeftSwipe){
     if(xCounter>-3){
         StartCoroutine(Roll(Vector3.left));
                 xCounter--;
                  timeToMoveCounter =0;
               }
                lastSwipe = LastSwipe.LEFT;
           }
          
        
          
        }else if (Input.GetKeyUp(KeyCode.RightArrow))
        {
            if(canRightSwipe){
                   if(xCounter<3){
                 StartCoroutine(Roll(Vector3.right));
                 xCounter++;
               timeToMoveCounter =0;
                   }
                        lastSwipe = LastSwipe.RIGHT;
            }
        }else if (Input.GetKeyUp(KeyCode.UpArrow)){
           if(canUpSwipe){
                if(zCounter<7){
                 StartCoroutine(Roll(Vector3.forward));
                 zCounter++;
                 timeToMoveCounter =0;
                }
             lastSwipe = LastSwipe.UP;
           }

              
             
        } else if (Input.GetKeyUp(KeyCode.DownArrow)){
            if(canDownSwipe){
                if(zCounter>0){
 StartCoroutine(Roll(Vector3.back));
                 zCounter--;
                   timeToMoveCounter =0;
                }
                      lastSwipe = LastSwipe.DOWN;
                 
        }
        }

    }

    void HandleTouchInput()
{
    // Eingaben nur zulassen, wenn das Spiel gestartet ist
    if ( Input.touchCount > 0)
    {
        Touch touch = Input.GetTouch(0);
        

        // Beim Beginn des Wischens, Position speichern
        if (touch.phase == TouchPhase.Began)
        {
            firstTouch = touch.position;
        }
        // Beim Ende des Wischens, Position prüfen und entscheiden, in welche Richtung der Spieler bewegt wird
        else if (touch.phase == TouchPhase.Ended)
        {
            lastTouch = touch.position;
            
            HandleSwipe(firstTouch, lastTouch);
            
            
        }
    }
}
    void HandleSwipe(Vector2 startTouch, Vector2 endTouch)
    {
        float swipeThreshold = 100; // Mindest-Swipe-Länge für eine Bewegung

        Vector2 swipeDirection = endTouch - startTouch;
        if (swipeDirection.magnitude >= swipeThreshold)
        {

            // Horizontaler Swipe
            if (Mathf.Abs(swipeDirection.x) > Mathf.Abs(swipeDirection.y))
            {
            
                if (swipeDirection.x > 0) // Swipe nach rechts
                {
                   if(canRightSwipe){
   if(xCounter<3){
                    StartCoroutine(Roll(Vector3.right));
                         timeToMoveCounter =0;
                         xCounter++;

                         }
                         lastSwipe = LastSwipe.RIGHT;

                   }
                    
                      
                   
                     
                }
                  
                else // Swipe nach links
                {
                    if(canLeftSwipe){
                            if(xCounter>-3){
                      StartCoroutine(Roll(Vector3.left));
                          timeToMoveCounter =0;
                                     xCounter--;
                              }
                              lastSwipe = LastSwipe.LEFT;
                    }
                    
                }
            }
            // Vertikaler Swipe
            else
            {
                if (swipeDirection.y > 0) // Swipe nach oben
                {
                    if(canUpSwipe){

              if(zCounter<7){
                    StartCoroutine(Roll(Vector3.forward));
                      timeToMoveCounter =0;
                      zCounter++;
              }
                  lastSwipe = LastSwipe.UP;
                    }
                }
                else // Swipe nach unten
                {
                    if(canDownSwipe){
         if(zCounter>0){
                  StartCoroutine(Roll(Vector3.back));
                   timeToMoveCounter =0;
                   zCounter--;
         }
         lastSwipe = LastSwipe.DOWN;
                    }
                }
            }
        }
    }

  

    


public void timeToMoveCountdown(){
    timeToMoveCounter+=Time.deltaTime;
    if(timeToMoveCounter>=timeToMoveMax){
    startAFKTimer = true;
    }else{
        startAFKTimer = false;
    }
    
    
}

public void afkCountdown(){
    if(levelManager.gameStarted){
  startAfkCounter-=Time.deltaTime;
    if(startAFKTimer){
    if(startAfkCounter<=0){
        GetComponent<PlayerCollision>().loose();
    }
     
}else{
    startAfkCounter = startAfkMax;
}

    }
  
}

void updatePlayerHasToMove(){
    if(playerHasToMove){


timeToMoveCountdown();
afkCountdown();


}

}


private void hideGameObjects( bool value){
    foreach(GameObject g in hideObjectWhenGameStarts){
        if(g!=null) g.SetActive(value);
    }
}
public void startGame(){
    levelManager.gameStarted = true;
    

}
IEnumerator Roll(Vector3 direction){
       soundManager.playSoundOneShot(SoundManager.SoundType.player, "player");
        levelManager.gameStarted = true;
canMove = false;
float remainingAngle = 90;
Vector3 rotationCenter = transform.position + direction /2 + Vector3.down/2;
Vector3 rotationAxis = Vector3.Cross(Vector3.up,direction);

while(remainingAngle>0){
    float rotationAngle = Mathf.Min(Time.deltaTime*speed,remainingAngle);
    transform.RotateAround(rotationCenter,rotationAxis,rotationAngle);
    remainingAngle-=rotationAngle;
   
yield return null;
}

canMove = true;

    

}


    }
