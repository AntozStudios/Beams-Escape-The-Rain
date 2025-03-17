using System.Collections.Generic;
using UnityEngine;
using System.Linq;

/// <summary>
/// Class that creates a random maze within a 2D array
/// </summary>
public class MazeGenerator : MonoBehaviour
{

    const bool Wall = true;
    const bool Passage = false;
    public GameObject _wallPrefab;

 
    public int _mazeWidth = 21;

    
    public int _mazeHeight = 21;

     private bool[,] _mazeGrid;


    private GameObject[,] _mazeStructure;

    [SerializeField] Transform spawnParent;


    void Start()
    {
    
        GenerateNewRandomMaze();
    }

    
    private void GenerateNewRandomMaze()
    {
        _mazeGrid = new bool[_mazeWidth, _mazeHeight];
        _mazeStructure = new GameObject[_mazeWidth, _mazeHeight];

        for (int x = 0; x < _mazeWidth; x++)
        {
            for (int y = 0; y < _mazeHeight; y++)
            {
                _mazeGrid[x, y] = Wall;
                _mazeStructure[x, y] = Instantiate(_wallPrefab, new Vector3( 1f, 0f, y * 1f), Quaternion.identity, GetComponent<Transform>());
            }
        }

        int startCellX = Random.Range(3, _mazeWidth - 3);
        int startCellY = Random.Range(3, _mazeHeight - 3);
        _mazeGrid[startCellX, startCellY] = Passage;

        HashSet<(int, int)> frontierCells = GetNeighborCells(startCellX, startCellY, true);

        while (frontierCells.Any())
        {
            int randomIndex = Random.Range(0, frontierCells.Count);
            (int, int) randomFrontierCell = frontierCells.ElementAt(randomIndex);
            int randomFrontierCellX = randomFrontierCell.Item1;
            int randomFrontierCellY = randomFrontierCell.Item2;
            _mazeGrid[randomFrontierCellX, randomFrontierCellY] = Passage;

            HashSet<(int, int)> candidateCells = GetNeighborCells(randomFrontierCellX, randomFrontierCellY, false);
            if (candidateCells.Any()) 
            {
                int randomIndexCandidate = Random.Range(0, candidateCells.Count);
                (int, int) randomCellConnection = candidateCells.ElementAt(randomIndexCandidate);
                int randomCellConnectionX = randomCellConnection.Item1;
                int randomCellConnectionY = randomCellConnection.Item2;

                (int, int) cellBetween;
                if (randomFrontierCellX < randomCellConnectionX)
                    cellBetween = (randomFrontierCellX + 1, randomFrontierCellY);
                else if (randomFrontierCellX > randomCellConnectionX)
                    cellBetween = (randomFrontierCellX - 1, randomFrontierCellY);
                else
                {
                    if (randomFrontierCellY < randomCellConnectionY)
                        cellBetween = (randomFrontierCellX, randomFrontierCellY + 1);
                    else
                        cellBetween = (randomFrontierCellX, randomFrontierCellY - 1);
                }

                _mazeGrid[cellBetween.Item1, cellBetween.Item2] = Passage;
            }

            frontierCells.Remove(randomFrontierCell);

            frontierCells.UnionWith(GetNeighborCells(randomFrontierCellX, randomFrontierCellY, true));
        }

       
        for (int x = 0; x < _mazeWidth; x++)
        {
            for (int y = 0; y < _mazeHeight; y++)
            {
                if (_mazeGrid[x, y] == Passage)
                    _mazeStructure[x, y].SetActive(false);
            }
        }
    }

   
    private HashSet<(int, int)> GetNeighborCells(int x, int y, bool checkFrontier)
    {
        HashSet<(int, int)> newNeighborCells = new HashSet<(int, int)>();


        if (x > 2)
        {
            (int, int) cellToCheck = (x - 2, y);

            if (checkFrontier ? _mazeGrid[cellToCheck.Item1, cellToCheck.Item2] == Wall : _mazeGrid[cellToCheck.Item1, cellToCheck.Item2] == Passage)
            {
                newNeighborCells.Add(cellToCheck);
            }
        }
        if (x < _mazeWidth - 3)
        {
            (int, int) cellToCheck = (x + 2, y);
            if (checkFrontier ? _mazeGrid[cellToCheck.Item1, cellToCheck.Item2] == Wall : _mazeGrid[cellToCheck.Item1, cellToCheck.Item2] == Passage)
            {
                newNeighborCells.Add(cellToCheck);
            }
        }

        if (y > 2)
        {
            (int, int) cellToCheck = (x, y - 2);
            if (checkFrontier ? _mazeGrid[cellToCheck.Item1, cellToCheck.Item2] == Wall : _mazeGrid[cellToCheck.Item1, cellToCheck.Item2] == Passage)
            {
                newNeighborCells.Add(cellToCheck);
            }
        }
        if (y < _mazeHeight - 3)
        {
            (int, int) cellToCheck = (x, y + 2);
            if (checkFrontier ? _mazeGrid[cellToCheck.Item1, cellToCheck.Item2] == Wall : _mazeGrid[cellToCheck.Item1, cellToCheck.Item2] == Passage)
            {
                newNeighborCells.Add(cellToCheck);
            }
        }

        return newNeighborCells;
    }
}