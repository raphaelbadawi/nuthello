// TESTS : de manière générale, rien de ce qui figure après la ligne 300 (partie POO) n'est encore vraiment testé, et le refactoring est indispensable pour y voir plus clair pour optimiser (c'est très lent en fin de partie)
// REFACTORING : des méthodes à splitter dans cette toute fraîche partie POO
// REFACTORING : transformer progressivement la partie procédurale en POO pour limiter les quasi-doublons (ex. de quasi-doublon : gameBoard réel global vs gameBoards virtuels stockés dans les mouvements possibles)
// REFACTORING : idéalement, créer des classes abstraites et des interfaces dont les implémentations distingueront plateaux réels et coups réels de plateaux virtuels et coups virtuels
// OPTIMISATION IA

/**
 *  NUTHELLO : a naked and greasy reversi game
 */
import java.util.*;

final int CELLSIZE = 100;
final int[][] DIRECTIONS = new int[][]{
  {-1, -1}, 
  {-1, 0}, 
  {-1, 1}, 
  {0, -1}, 
  {0, 1}, 
  {1, -1}, 
  {1, 0}, 
  {1, 1}
};

final int BLACK = 0;
final int WHITE = 250;

// IA anticipates three turns ahead
final int ANTICIPATION_LEVEL = 3;

// levels go from easy (0) to hard (2)
int level = 2;
int[][][] gameBoard = new int[8][8][2];

int selfColor;
int opponentColor;

boolean isOddTurn = true;
boolean canPlay = false;
boolean gameIsEnded = false;


void setup() {
  seedGameBoard();
  size(1200, 900);
}

void seedGameBoard() {
  gameBoard[3][3][0] = 1;
  gameBoard[3][3][1] = BLACK;
  gameBoard[4][4][0] = 1;
  gameBoard[4][4][1] = BLACK;
  gameBoard[3][4][0] = 1;
  gameBoard[3][4][1] = WHITE;
  gameBoard[4][3][0] = 1;
  gameBoard[4][3][1] = WHITE;
}

void draw() {
  background(0);
  initGameBoard();
}

void initGameBoard() {
  selfColor = getSelfPawnColor();
  opponentColor = getOpponentPawnColor();
  // clarification: gameBoard dimensions order is rows then columns while coordinates order is width (columns) then height (rows)
  translate(width/2 - ((CELLSIZE * gameBoard[0].length) / 2), height/2 - ((CELLSIZE * gameBoard.length) / 2));
  fill(WHITE);
  textSize(32);
  textAlign(CENTER);
  text(isOddTurn ? "Sarah Connor" : "Skynet", (CELLSIZE * gameBoard[0].length) / 2, -10);
  for (int i = 0; i < gameBoard.length; i++) {
    for (int j = 0; j < gameBoard[i].length; j++) {
      drawCell(j, i);
      if (gameBoard[i][j][0] == 1) {
        drawPawn(j, i, gameBoard[i][j][1], CELLSIZE * 0.75);
      } else if (isPlayable(j, i)) {
        drawPawn(j, i, isOddTurn ? BLACK : WHITE, CELLSIZE * 0.25);
        canPlay = true;
      }
    }
  }
  if (!canPlay) {
    endGameHandler();
  }
  canPlay = false;
}

int getSelfPawnColor() {
  return isOddTurn ? BLACK : WHITE;
}

int getOpponentPawnColor() {
  return isOddTurn ? WHITE : BLACK;
}

void drawCell(int x, int y) {
  fill(124, 148, 115);
  rect(x * CELLSIZE, y * CELLSIZE, CELLSIZE, CELLSIZE);
}

void drawPawn(int x, int y, int colorValue, float sizeValue) {
  fill(colorValue);
  circle(x * CELLSIZE + CELLSIZE / 2, y * CELLSIZE + CELLSIZE / 2, sizeValue);
}

void endGameHandler() {
  fill(250, 0, 0);
  textSize(64);
  textAlign(CENTER);
  text("I'LL BE BACK", (CELLSIZE * gameBoard[0].length) / 2, (CELLSIZE * gameBoard.length) / 2);
}


void mouseClicked() {
  if (gameIsEnded) {
    seedGameBoard();
    gameIsEnded = true;
  }

  int[] clickedCoordinates = getClickedCoordinates(mouseX, mouseY);
  if (clickedCoordinates[0] < 0 || clickedCoordinates[0] >= gameBoard[0].length || clickedCoordinates[1] < 0 || clickedCoordinates[1] >= gameBoard.length) {
    return;
  }
  if (isOddTurn && isPlayable(clickedCoordinates[0], clickedCoordinates[1])) {
    pushNewPawn(clickedCoordinates[0], clickedCoordinates[1]);
    setAllFlippableCoins(clickedCoordinates[0], clickedCoordinates[1]);
    flipCoins();
    changePlayer();
  } else if (!isOddTurn) {
    computerPlays();
    changePlayer();
  }
}

int[] getClickedCoordinates(int x, int y) {
  float offsetX = (width - (CELLSIZE * gameBoard.length)) / 2;
  float offsetY = (height - (CELLSIZE * gameBoard[0].length)) / 2;
  int cellX = (int) Math.floor((x - offsetX) / CELLSIZE);
  int cellY = (int) (Math.floor((y - offsetY)/ CELLSIZE));
  return new int[]{cellX, cellY};
}

void pushNewPawn(int x, int y) {
  if (x >= 0 && y >= 0) {
    gameBoard[y][x][0] = 1;
    gameBoard[y][x][1] = selfColor;
  }
}

void changePlayer() {
  isOddTurn = !isOddTurn;
}


boolean isValidMove = false;
int pawnsCounter = 0;

boolean isPlayable(int x, int y) {
  return traverseAllDirections(x, y);
}

// also resets counters and returns if move is valid
boolean traverseAllDirections(int x, int y) {
  resetCounter();
  for (int[] direction : DIRECTIONS) {
    isValidMove = false;
    traverseDirection(x, y, direction, 0);
    if (isValidMove) return true;
  }
  return false;
}

void resetCounter() {
  pawnsCounter = 0;
}

// also increments counter
boolean traverseDirection(int x, int y, int[] direction, int recursivityLevel) {
  x += direction[0];
  y += direction[1];

  // is it on the board?
  if (x >= 0 && x < gameBoard[0].length && y >= 0 && y < gameBoard.length) {
    if (gameBoard[y][x][0] == 1 && gameBoard[y][x][1] == opponentColor) {
      pawnsCounter++;
      traverseDirection(x, y, direction, recursivityLevel + 1);
    } else if (recursivityLevel > 0 && gameBoard[y][x][0] == 1 && gameBoard[y][x][1] == selfColor) {
      isValidMove = true;
      return true;
    }
    // is there a hole?
    return false;
  }
  return false;
}


ArrayList<Integer[]> flippableCoins;

void setAllFlippableCoins(int x, int y) {
  flippableCoins = new ArrayList<Integer[]>();
  for (int[] direction : DIRECTIONS) {
    setOneDirectionlFlippableCoins(x, y, direction, 0);
  }
}

int flippableCoinsCursor = 0;

void setOneDirectionlFlippableCoins(int x, int y, int[] direction, int recursivityLevel) {
  x += direction[0];
  y += direction[1];

  if (x >= 0 && x < gameBoard[0].length && y >= 0 && y < gameBoard.length) {
    if (gameBoard[y][x][0] == 1 && gameBoard[y][x][1] == opponentColor) {
      flippableCoins.add(new Integer[]{x, y});
      flippableCoinsCursor++;
      setOneDirectionlFlippableCoins(x, y, direction, recursivityLevel + 1);
    } else if (recursivityLevel > 0 && gameBoard[y][x][0] == 1 && gameBoard[y][x][1] == selfColor) {
      flippableCoinsCursor = 0;
      return;
    }
    removeInvalidFlippableCoins();
  }
  removeInvalidFlippableCoins();
}

void removeInvalidFlippableCoins() {
  for (int i = 1; i <= flippableCoinsCursor && flippableCoins.size() > i; i++) {
    flippableCoins.remove(flippableCoins.size() - i);
  }
  flippableCoinsCursor = 0;
}

void flipCoins() {
  for (Integer[] flippableCoin : flippableCoins) {
    gameBoard[flippableCoin[1]][flippableCoin[0]][1] = selfColor;
  }
}

void computerPlays() {
  float[] levelsRandomness = new float[]{0.33, 0.66, 1};
  Integer[] currentMove = Math.random() >= levelsRandomness[level] ? getRandomMove() : getBestMove();

  pushNewPawn(currentMove[0], currentMove[1]);
  setAllFlippableCoins(currentMove[0], currentMove[1]);
  flipCoins();
}

Integer[] getRandomMove() {
  ArrayList<Integer[]> playableCells = getPlayableCells();
  int randomIndex = (int) Math.floor(Math.random() * playableCells.size());
  return playableCells.get(randomIndex);
}

ArrayList<Integer[]> getPlayableCells() {
  ArrayList<Integer[]> playableCells = new ArrayList<Integer[]>();
  for (int i = 0; i < gameBoard.length; i++) {
    for (int j = 0; j < gameBoard[i].length; j++) {
      if (gameBoard[i][j][0] != 1 && isPlayable(j, i)) {
        playableCells.add(new Integer[]{j, i});
      }
    }
  }
  return playableCells;
}

int currentBestMoveScore = 0;

Integer[] getBestMove() {
  Integer[] currentMove = new Integer[]{-1, -1};
  int currentCount = 0;
  ArrayList<Integer[]> playableCells = getPlayableCells();

  for (Integer[] playableCell : playableCells) {
    int x = playableCell[0];
    int y = playableCell[1];

    MoveTree treeOfInfiniteWondersAndPossibilitiesOhGodJeBandeCommeUnAne = new MoveTree(gameBoard, x, y);
    currentCount = treeOfInfiniteWondersAndPossibilitiesOhGodJeBandeCommeUnAne.bestScoreAhead;
    currentMove = treeOfInfiniteWondersAndPossibilitiesOhGodJeBandeCommeUnAne.getBestMoveCoordinates();

    if (currentCount > currentBestMoveScore) {
      currentBestMoveScore = currentCount;
      currentMove = treeOfInfiniteWondersAndPossibilitiesOhGodJeBandeCommeUnAne.getBestMoveCoordinates();
    }
  };

  return currentMove;
}

boolean isInBorder(int x, int y) {
  if (x == 0 || x == 7 || y == 0 || y == 7) {
    return true;
  }

  return false;
}

boolean isInCoin(int x, int y) {
  if ((x == 0 && y == 0) || (x == 0 && y == 7) || (x == 7 && y == 0) || (x == 7 && y == 7)) {
    return true;
  }

  return false;
}


// from here onwards, moves refer to potential moves, not to real ones
class Move {
  int[][][] gameBoard;
  int x;
  int y;
  int score;
  int level;
  UUID parentIndex;
  UUID index;

  ArrayList<Move> children = new ArrayList<Move>();

  Move(int[][][] gameBoard, int x, int y, int level, UUID parentIndex) {
    this.gameBoard = gameBoard;
    this.x = x;
    this.y = y;
    this.level = level;
    this.parentIndex = parentIndex;
    this.index = UUID.randomUUID();
    this.calculateIntrinsicScore();
    this.updateGameBoard();
  }

  public void simulateMove() {
    this.calculateIntrinsicScore();
    this.updateGameBoard();
  }

  private void calculateIntrinsicScore() {
    traverseAllDirections(this.x, this.y);
    this.score = isInCoin(this.x, this.y) ? pawnsCounter + 7 : (isInBorder(this.x, this.y) ? pawnsCounter + 3 : pawnsCounter);
  }

  // TODO : condensé à l'arrache de trois fonctions procédurales en une : splitter tout ça en trois méthodes appelées depuis une méthode mère
  private void updateGameBoard() {
    ArrayList<Integer[]> flippableCoins = new ArrayList<Integer[]>();
    int flippableCoinsCursor = 0;

    for (int[] direction : DIRECTIONS) {
      int recursivityLevel = 0;
      int newX = this.x;
      int newY = this.y;
      newX += direction[0];
      newY += direction[1];

      if (newX >= 0 && newX < gameBoard[0].length && newY >= 0 && newY < gameBoard.length) {
        if (this.gameBoard[newY][newX][0] == 1 && this.gameBoard[newY][newX][1] == opponentColor) {
          flippableCoins.add(new Integer[]{newX, newY});
          flippableCoinsCursor++;
          setOneDirectionlFlippableCoins(newX, newY, direction, recursivityLevel + 1);
        } else if (recursivityLevel > 0 && gameBoard[newY][newX][0] == 1 && gameBoard[newY][newX][1] == selfColor) {
          flippableCoinsCursor = 0;
          return;
        }
        for (int i = 1; i <= flippableCoinsCursor && flippableCoins.size() >= i; i++) {
          flippableCoins.remove(flippableCoins.size() - i);
        }
        flippableCoinsCursor = 0;
      }
      for (int i = 1; i <= flippableCoinsCursor && flippableCoins.size() > i; i++) {
        flippableCoins.remove(flippableCoins.size() - i);
      }
      flippableCoinsCursor = 0;
    }
    for (Integer[] flippableCoin : flippableCoins) {
      gameBoard[flippableCoin[1]][flippableCoin[0]][1] = selfColor;
    }
  }

  public void add(int[][][] gameBoard, int x, int y, int level) {
    Move child = new Move(gameBoard, x, y, level, index);
    this.children.add(child);
  }
}

class MoveTree {
  int[][][] initialGameBoardState;
  Move rootMove;
  Move bestMoveAhead;
  int bestScoreAhead = 0;
  HashMap<UUID, Integer> indexToScoreMap = new HashMap<UUID, Integer>();

  MoveTree(int[][][] gameBoard, int x, int y) {
    this.initialGameBoardState = gameBoard;
    this.rootMove = new Move(gameBoard, x, y, 0, UUID.randomUUID());
    this.seedTree(this.rootMove, 0);
    this.traverseTreeFromTop(this.rootMove);
    this.evaluateScores();
  }

  private void seedTree(Move currentNode, int currentLevel) {
    if (currentLevel < ANTICIPATION_LEVEL) {
      for (Integer[] playableCell : this.getPlayableCells(currentNode.gameBoard)) {
        currentNode.add(this.initialGameBoardState, playableCell[0], playableCell[1], currentLevel + 1);
      }
      for (Move child : currentNode.children) {
        child.simulateMove();
        this.seedTree(child, currentLevel + 1);
      }
    }
  }

  private ArrayList<Integer[]> getPlayableCells(int[][][] conjecturalGameBoard) {
    ArrayList<Integer[]> playableCells = new ArrayList<Integer[]>();
    for (int i = 0; i < conjecturalGameBoard.length; i++) {
      for (int j = 0; j < conjecturalGameBoard[i].length; j++) {
        if (conjecturalGameBoard[i][j][0] != 1 && isPlayable(j, i)) {
          playableCells.add(new Integer[]{j, i});
        }
      }
    }
    return playableCells;
  }

  private void traverseTreeFromTop(Move currentNode) {
    for (Move child : currentNode.children) {
      if (child.children.size() > 0) {
        this.traverseTreeFromTop(child);
      } else {
        calculateTotalScores(child);
      }
    }
  }

  private void calculateTotalScores(Move child) {
    this.indexToScoreMap.put(child.index, child.level % 2 == 0 ? +child.score : -child.score);
    if (child.parentIndex != rootMove.parentIndex) {
      Move parentNode = getParentNode(child.parentIndex);
      this.incrementScore(child.index, parentNode);
    }
  }

  private void incrementScore(UUID finalChildIndex, Move child) {
    int currentPathScore = this.indexToScoreMap.get(finalChildIndex);
    this.indexToScoreMap.put(finalChildIndex, child.level % 2 == 0 ? currentPathScore + child.score : currentPathScore - child.score);
    if (child.parentIndex != rootMove.parentIndex) {
      Move parentNode = getParentNode(child.parentIndex);
      this.incrementScore(finalChildIndex, parentNode);
    }
  }

  // cette méthode ne retourne pas systématiquement quelque chose, d'où les tours sautés, l'investigation continue
  private void evaluateScores() {
    UUID indexStamp = UUID.randomUUID();
    for (HashMap.Entry<UUID, Integer> indexToScore : indexToScoreMap.entrySet()) {
      if (indexToScore.getValue() > bestScoreAhead) {
        indexStamp = indexToScore.getKey();
        bestScoreAhead = indexToScore.getValue();
      }
    };
    this.bestMoveAhead = getFinalParent(getMoveByIndex(this.rootMove, indexStamp));
  }

  private Move getFinalParent(Move currentNode) {
    if (currentNode.parentIndex != this.rootMove.parentIndex) {
      Move parentNode = getParentNode(currentNode.parentIndex);
      getFinalParent(parentNode);
    }
    return currentNode;
  }

  private Move getParentNode(UUID parentIndex) {
    for (Move potentialParent : this.rootMove.children) {
      if (potentialParent.index == parentIndex) {
        return potentialParent;
      }
      getParentNode(potentialParent.index);
    }
    return this.rootMove;
  }

  private Move getMoveByIndex(Move currentNode, UUID index) {
    for (Move child : currentNode.children) {
      if (child.index == index) {
        return child;
      } else {
        getMoveByIndex(child, index);
      }
    }
    return this.rootMove;
  }

  public Integer[] getBestMoveCoordinates() {
    return new Integer[]{this.bestMoveAhead.x, this.bestMoveAhead.y};
  }
}
