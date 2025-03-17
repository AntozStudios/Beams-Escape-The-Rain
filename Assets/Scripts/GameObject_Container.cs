using UnityEngine;

public class GameObject_Container : MonoBehaviour
{
    public static GameObject_Container Instance;
    public GameObject nextLevel;
    public GameObject pivotObject;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(this); 
        }
        else
        {
            Destroy(this); 
        }
    }
}
