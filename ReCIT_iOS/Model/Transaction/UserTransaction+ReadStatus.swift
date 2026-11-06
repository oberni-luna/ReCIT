//
//  UserTransaction+ReadStatus.swift
//  ReCIT_iOS
//
//  Created by Olivier Berni on 06/11/2026.
//

extension UserTransaction {
    /// Read by the reader whose id is `userId`, on whichever side of the Échange they stand:
    /// the rule a tinted dot is drawn by, wherever one says an Échange waits to be read — on its
    /// row (`TransactionCellView`) and after « Échanges • N » on a friend's profile.
    func isRead(by userId: String?) -> Bool {
        requester._id == userId ? readStatus.requester == false : readStatus.owner == false
    }
}
