from flask import Blueprint, request, jsonify
from ..services.user_service import UserService

user_blueprint = Blueprint('user', __name__)

@user_blueprint.route('/users', methods=['GET'])
def get_users():
    users = UserService.get_all_users()
    return jsonify([user.to_dict() for user in users])

@user_blueprint.route('/users', methods=['POST'])
def create_user():
    try:
        # Get JSON data from the request
        data = request.get_json()

        # Validate required fields
        if not data or 'username' not in data or 'email' not in data:
            return jsonify({"error": "Missing required fields"}), 400

        # Call the service method to create a user
        user = UserService.create_user(data)

        # Return the created user as JSON
        return jsonify(user.to_dict()), 201

    except Exception as e:
        # Handle any other unexpected errors
        return jsonify({"error": "An unexpected error occurred"}), 500
