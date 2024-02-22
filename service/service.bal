import ballerina/http;

final Room[] rooms = getAllRooms();
table<Reservation> key(id) roomReservations = table [];

service /reservations on new http:Listener(9090) {

    resource function post .(NewReservationRequest payload) returns Reservation|NewReservationError|error? {
        // Complete the implementation to check whether a room is available for the given dates
        // Use getAvailableRoom function to check whether a room is available
        // And create a new reservation if room is available
        Room|() availableRoom = check getAvailableRoom(payload.checkinDate, payload.checkoutDate, payload.roomType);
        if availableRoom is () {
            return {body: "No rooms available for given dates"};
        }
        Reservation reservation = {
            checkinDate: payload.checkinDate,
            checkoutDate: payload.checkoutDate,
            id: roomReservations.length() + 1,
            user: payload.user,
            room: availableRoom
        };
        roomReservations.add(reservation);
        sendNotificationForReservation(reservation, "Created");
        return reservation;
    }

    resource function put [int reservationId](UpdateReservationRequest payload) returns Reservation|UpdateReservationError|error {
        Reservation? reservation = roomReservations[reservationId];
        if (reservation is ()) {
            return {body: "Reservation not found"};
        }
        Room? room = check getAvailableRoom(payload.checkinDate, payload.checkoutDate, reservation.room.'type.name);
        if (room is ()) {
            return {body: "No rooms available for the given dates"};
        }
        reservation.room = room;
        reservation.checkinDate = payload.checkinDate;
        reservation.checkoutDate = payload.checkoutDate;
        sendNotificationForReservation(reservation, "Updated");
        return reservation;
    }

    resource function delete [int reservationId]() returns http:NotFound|http:Ok {
        if (roomReservations.hasKey(reservationId)) {
            _ = roomReservations.remove(reservationId);
            return http:OK;
        } else {
            return http:NOT_FOUND;
        }
    }

    resource function get users/[string userId]() returns Reservation[] {
        return from Reservation r in roomReservations
            where r.user.id == userId
            select r;
    }

    resource function get roomTypes(string checkinDate, string checkoutDate, int guestCapacity) returns RoomType[]|error {
        return getAvailableRoomTypes(checkinDate, checkoutDate, guestCapacity);
    }
}
