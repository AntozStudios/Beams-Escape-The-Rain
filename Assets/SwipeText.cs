using UnityEngine;
using UnityEngine.UI;

public class SwipeText : MonoBehaviour
{
    [SerializeField] GameObject player;
    void Awake(){
        GetComponent<Button>().onClick.AddListener(()=>Destroy(gameObject));
    }

  void OnDestroy(){
    Debug.Log(true);
    player.GetComponent<PlayerMovement>().canMove = true;
  }
}
