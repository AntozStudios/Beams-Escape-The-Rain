using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FollowPlayer : MonoBehaviour
{
    public Transform player;
    public Vector3 offset;
    void Start()
    {
        
    }

     private void LateUpdate()
    {
        if (player != null)
        {
            // Position der Kamera basierend auf der Spielerposition und dem Offset aktualisieren.
            transform.position = player.position + offset;
        }
    }
}
