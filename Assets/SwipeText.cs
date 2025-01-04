using UnityEngine;
using UnityEngine.UI;

public class SwipeText : MonoBehaviour
{
    [SerializeField] GameObject player;
    void Awake(){
        GetComponent<Button>().onClick.AddListener(()=>Destroy(gameObject));
    }

  void OnDestroy(){

    if(player!=null){
  player.GetComponent<PlayerMovement>().canMove = true;
    }
  
  }
}
