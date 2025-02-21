using System.Collections.Generic;
using UnityEngine;

public class CreateField : MonoBehaviour
{
    [SerializeField] private GameObject topPrefab;
    [SerializeField] private GameObject levelPart;
  
    [HideInInspector] public GameObject startTop;
    
    private MyPoint myPoint = new MyPoint(); // Initialisierung von myPoint

    public enum SpawnObject{
        CENTER,
        LEFT,
        RIGHT,
        BACK,
        RANDOM
    }
    SpawnObject sp;

    private RainSpawner rainSpawner;
    private GameObject pivotObject;
    private int x, z;
    public GameObject[,] field;

    void Awake()
    {
        x = (int)levelPart.transform.localScale.x;
        z = (int)levelPart.transform.localScale.z;
        
        field = new GameObject[x, z];
        rainSpawner = GetComponentInParent<RainSpawner>();

        if (topPrefab == null || levelPart == null)
        {
            Debug.LogError("topPrefab oder levelPart ist nicht zugewiesen.");
            return;
        }

        for (int i = 0; i < x; i++)
        {
            for (int j = 0; j < z; j++)
            {
                pivotObject = Instantiate(topPrefab, transform);
                pivotObject.name = "i: " + i + " j: " + j;
                field[i, j] = pivotObject;

                float posX = levelPart.transform.position.x - (levelPart.transform.localScale.x / 2) + (pivotObject.transform.localScale.x / 2);
                float posY = levelPart.transform.position.y + (levelPart.transform.localScale.y / 2) + (pivotObject.transform.localScale.y / 2);
                float posZ = levelPart.transform.position.z - (levelPart.transform.localScale.z / 2) + (pivotObject.transform.localScale.z / 2);

                pivotObject.transform.position = new Vector3(posX + (pivotObject.transform.localScale.x * i), posY, posZ + (pivotObject.transform.localScale.z * j));

                if (i == x / 2 && j == 0)
                {
                    startTop = pivotObject;
                }

              
// Hardcode to avoid 0,0
//Avoiding Rain for targetField
bool left = (i!=x/2)&&( j!=z-1);
bool right = (i != 3) && (j != 0);
                  if(left || right) {
Debug.Log(i+"  "+j);
      rainSpawner.tops.Add(pivotObject);
                }
                
              
                
            }
        }
    }

    private void spawnObjectToTile(int column, int row, GameObject from)
    {
        Instantiate(from, field[column, row].transform).transform.position = new Vector3(
            field[column, row].transform.position.x,
            pivotObject.transform.position.y + from.transform.localScale.y,
            field[column, row].transform.position.z);
            myPoint = new MyPoint(column,row);
    }

    public void spawnObject(SpawnObject mode, GameObject gameObject)
    {
        switch (mode)
        {
            case SpawnObject.CENTER:
                spawnObjectToTile(x - 2, (z / 2) - 1, gameObject);
         
                break;
            case SpawnObject.BACK:
                spawnObjectToTile(x/2,z-1, gameObject);
            
                break;
            case SpawnObject.LEFT:
                spawnObjectToTile(0, (z / 2) - 1, gameObject);
             
                break;
            case SpawnObject.RIGHT:
                spawnObjectToTile(x - 1, (z / 2) - 1, gameObject);
                
                break;
            case SpawnObject.RANDOM:
                break;
        }
        Debug.Log($"myPoint: x={myPoint.x}, z={myPoint.z}");
    }

    public void drawField(Material material)
    {
        for (int i = 0; i < x; i++)
        {
            for (int j = 0; j < z; j++)
            {
                field[i, j].GetComponent<Renderer>().material = material;
            }
        }
    }
}

public class MyPoint {
    public int x, z;
    public MyPoint() { x = 0; z = 0; }
    public MyPoint(int x, int z) { this.x = x; this.z = z; }
}
