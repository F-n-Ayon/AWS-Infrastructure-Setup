from flask import Flask, render_template, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import json
import os
import logging
from datetime import datetime
from sqlalchemy import desc

app = Flask(__name__)

# Database configuration
db_host = os.getenv('DB_HOST', 'localhost')
db_port = os.getenv('DB_PORT', '5432')
db_name = os.getenv('DB_NAME', 'appdb')
db_user = os.getenv('DB_USER', 'appuser')
db_password = os.getenv('DB_PASSWORD', 'ChangeMe123!')

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Log startup
logger.info("=" * 60)
logger.info("Tic-Tac-Toe Application Starting")
logger.info("=" * 60)
logger.info(f"Environment: {os.getenv('ENVIRONMENT', 'unknown')}")
logger.info(f"Database Host: {os.getenv('DB_HOST', 'Not configured')}")
logger.info(f"Database Name: {os.getenv('DB_NAME', 'Not configured')}")
logger.info("=" * 60)

# Database Models
class Player(db.Model):
    __tablename__ = 'players'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    wins = db.Column(db.Integer, default=0)
    losses = db.Column(db.Integer, default=0)
    draws = db.Column(db.Integer, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    games = db.relationship('Game', backref='player', lazy=True)

    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'wins': self.wins,
            'losses': self.losses,
            'draws': self.draws,
            'total_games': self.wins + self.losses + self.draws,
            'win_rate': round((self.wins / (self.wins + self.losses + self.draws) * 100), 2) if (self.wins + self.losses + self.draws) > 0 else 0
        }

class Game(db.Model):
    __tablename__ = 'games'
    id = db.Column(db.Integer, primary_key=True)
    player_id = db.Column(db.Integer, db.ForeignKey('players.id'), nullable=False)
    opponent = db.Column(db.String(80), default='Computer')
    winner = db.Column(db.String(80), nullable=True)
    moves = db.Column(db.JSON, default=[])
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    duration_seconds = db.Column(db.Integer, default=0)

    def to_dict(self):
        return {
            'id': self.id,
            'player_id': self.player_id,
            'opponent': self.opponent,
            'winner': self.winner,
            'moves_count': len(self.moves) if self.moves else 0,
            'created_at': self.created_at.isoformat(),
            'duration_seconds': self.duration_seconds
        }

# Initialize game state
game_state = {
    "board": [""] * 9,
    "current_player": "X",
    "winner": None,
    "game_over": False,
    "current_player_id": None,
    "start_time": None,
    "moves": []
}

def check_winner(board):
    # Winning combinations: rows, columns, diagonals
    wins = [
        [0, 1, 2], [3, 4, 5], [6, 7, 8],  # Rows
        [0, 3, 6], [1, 4, 7], [2, 5, 8],  # Columns
        [0, 4, 8], [2, 4, 6]              # Diagonals
    ]
    for win in wins:
        if board[win[0]] == board[win[1]] == board[win[2]] != "":
            return board[win[0]]
    if "" not in board:
        return "Draw"
    return None

@app.route('/')
def index():
    logger.info("Game UI requested")
    return render_template('index.html')

@app.route('/health')
def health():
    """Health check endpoint for ALB"""
    logger.debug("Health check request received")
    return jsonify({"status": "healthy", "service": "tic-tac-toe-app"}), 200

@app.route('/healthz')
def healthz():
    """Kubernetes-style health check endpoint"""
    logger.debug("Kubernetes health check request")
    return jsonify({"status": "ok"}), 200

@app.route('/live')
def live():
    """Liveness probe - is the app running?"""
    logger.debug("Liveness probe check")
    return jsonify({"alive": True, "timestamp": str(datetime.now())}), 200

@app.route('/ready')
def ready():
    """Readiness probe - is the app ready to serve requests?"""
    logger.debug("Readiness probe check")
    try:
        # Try to connect to database
        db.session.execute('SELECT 1')
        return jsonify({"ready": True, "service": "tic-tac-toe-app"}), 200
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        return jsonify({"ready": False, "error": "Database not available"}), 503

# Player endpoints
@app.route('/api/player', methods=['POST'])
def create_player():
    """Create a new player"""
    try:
        data = request.get_json()
        username = data.get('username')
        
        if not username:
            return jsonify({"error": "Username required"}), 400
        
        # Check if player exists
        existing_player = Player.query.filter_by(username=username).first()
        if existing_player:
            return jsonify({"player": existing_player.to_dict()}), 200
        
        # Create new player
        new_player = Player(username=username)
        db.session.add(new_player)
        db.session.commit()
        
        logger.info(f"New player created: {username}")
        return jsonify({"player": new_player.to_dict()}), 201
    except Exception as e:
        logger.error(f"Error creating player: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/player/<int:player_id>', methods=['GET'])
def get_player(player_id):
    """Get player profile and statistics"""
    try:
        player = Player.query.get(player_id)
        if not player:
            return jsonify({"error": "Player not found"}), 404
        return jsonify({"player": player.to_dict()}), 200
    except Exception as e:
        logger.error(f"Error fetching player: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/leaderboard', methods=['GET'])
def get_leaderboard():
    """Get top players by win rate"""
    try:
        limit = request.args.get('limit', 10, type=int)
        players = Player.query.order_by(desc(Player.wins)).limit(limit).all()
        return jsonify({"leaderboard": [p.to_dict() for p in players]}), 200
    except Exception as e:
        logger.error(f"Error fetching leaderboard: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/game/start', methods=['POST'])
def start_game():
    """Start a new game"""
    try:
        data = request.get_json()
        player_id = data.get('player_id')
        
        global game_state
        game_state = {
            "board": [""] * 9,
            "current_player": "X",
            "winner": None,
            "game_over": False,
            "current_player_id": player_id,
            "start_time": datetime.now(),
            "moves": []
        }
        
        logger.info(f"New game started for player {player_id}")
        return jsonify({"game": game_state}), 200
    except Exception as e:
        logger.error(f"Error starting game: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/move', methods=['POST'])
def move():
    global game_state
    try:
        data = request.get_json()
        index = data['index']
        logger.info(f"Move requested: Player {game_state['current_player']} at position {index}")

        if game_state['game_over'] or game_state['board'][index] != "":
            logger.warning(f"Invalid move attempted at position {index}")
            return jsonify({"error": "Invalid move"}), 400

        # Update board
        game_state['board'][index] = game_state['current_player']
        game_state['moves'].append({
            "player": game_state['current_player'],
            "position": index,
            "timestamp": datetime.now().isoformat()
        })
        
        # Check for winner
        winner = check_winner(game_state['board'])
        if winner:
            game_state['winner'] = winner
            game_state['game_over'] = True
            
            # Save game to database
            if game_state['current_player_id']:
                duration = (datetime.now() - game_state['start_time']).total_seconds()
                game = Game(
                    player_id=game_state['current_player_id'],
                    winner=winner,
                    moves=game_state['moves'],
                    duration_seconds=int(duration)
                )
                db.session.add(game)
                
                # Update player stats
                player = Player.query.get(game_state['current_player_id'])
                if player:
                    if winner == "Draw":
                        player.draws += 1
                    elif winner == "X":
                        player.wins += 1
                    else:
                        player.losses += 1
                    db.session.commit()
            
            logger.info(f"Game Over! Winner: {winner}")
        else:
            # Switch player
            game_state['current_player'] = "O" if game_state['current_player'] == "X" else "X"
            logger.info(f"Turn switched to: {game_state['current_player']}")

        return jsonify(game_state), 200
    except Exception as e:
        logger.error(f"Error processing move: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/game/state', methods=['GET'])
def get_game_state():
    """Get current game state"""
    return jsonify(game_state), 200

@app.route('/api/player/<int:player_id>/games', methods=['GET'])
def get_player_games(player_id):
    """Get game history for a player"""
    try:
        limit = request.args.get('limit', 20, type=int)
        games = Game.query.filter_by(player_id=player_id).order_by(desc(Game.created_at)).limit(limit).all()
        return jsonify({"games": [g.to_dict() for g in games]}), 200
    except Exception as e:
        logger.error(f"Error fetching games: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/init', methods=['POST'])
def init_game():
    """Initialize a new game session"""
    global game_state
    game_state = {
        "board": [""] * 9,
        "current_player": "X",
        "winner": None,
        "game_over": False,
        "current_player_id": None,
        "start_time": datetime.now(),
        "moves": []
    }
    logger.info("New game initialized")
    return jsonify(game_state), 200

@app.route('/reset', methods=['POST'])
def reset():
    global game_state
    game_state['board'] = [""] * 9
    game_state['current_player'] = "X"
    game_state['winner'] = None
    game_state['game_over'] = False
    game_state['moves'] = []
    game_state['start_time'] = datetime.now()
    logger.info("Game reset")
    return jsonify(game_state), 200

if __name__ == '__main__':
    with app.app_context():
        try:
            db.create_all()
            logger.info("Database tables initialized")
        except Exception as e:
            logger.warning(f"Could not initialize database: {str(e)}")
    
    app.run(host='0.0.0.0', port=5000, debug=False)