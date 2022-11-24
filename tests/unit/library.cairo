// SPDX-License-Identifier: MIT

%lang starknet

// Starkware dependencies
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_eq, ALL_ONES

// Project dependencies
from openzeppelin.security.safemath.library import SafeUint256
from openzeppelin.token.erc721.library import ERC721

from carbonable.erc3525.library import ERC3525
from carbonable.erc3525.utils.constants.library import IERC3525_RECEIVER_ID

namespace assert_that {
    func ERC721_balance_of_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        owner: felt, expected_balance: Uint256
    ) {
        alloc_locals;
        let (returned_balance: Uint256) = ERC721.balance_of(owner);
        let (is_eq) = uint256_eq(returned_balance, expected_balance);
        assert 1 = is_eq;
        return ();
    }

    func slot_of_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, expected_slot: Uint256
    ) {
        alloc_locals;
        let (returned_slot: Uint256) = ERC3525.slot_of(token_id);
        let (is_eq) = uint256_eq(returned_slot, expected_slot);
        assert 1 = is_eq;
        return ();
    }

    func owner_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, expected_owner: felt
    ) {
        let (returned_owner) = ERC721.owner_of(token_id);
        assert returned_owner = expected_owner;
        return ();
    }

    func ERC3525_balance_of_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, expected_balance: Uint256
    ) {
        alloc_locals;
        let (returned_balance: Uint256) = ERC3525.balance_of(token_id);
        let (is_eq) = uint256_eq(returned_balance, expected_balance);
        assert 1 = is_eq;
        return ();
    }

    func allowance_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id: Uint256, operator: felt, expected_allowance: Uint256
    ) {
        alloc_locals;
        let (returned_allowance: Uint256) = ERC3525.allowance(token_id, operator);
        let (is_eq) = uint256_eq(returned_allowance, expected_allowance);
        assert 1 = is_eq;
        return ();
    }
}

namespace it {
    func transfers{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, caller: felt}(
        from_token_id: Uint256, to: felt, value: Uint256
    ) {
        alloc_locals;

        let (local old_owner) = ERC721.owner_of(from_token_id);
        let (local old_bal721_from) = ERC721.balance_of(old_owner);
        let (local old_bal721_to) = ERC721.balance_of(to);
        let (local old_bal_from) = ERC3525.balance_of(from_token_id);
        let (local old_slot) = ERC3525.slot_of(from_token_id);

        %{
            stop_prank = start_prank(ids.caller) 
            mock_call(ids.to, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
            mock_call(ids.to, "supportsInterface", [ids.TRUE])
            expect_events({"name": "TransferValue"})
        %}
        let (new_token_id) = ERC3525.transfer_from(from_token_id, Uint256(0, 0), to, value);
        %{ stop_prank() %}

        let (bal_from) = ERC3525.balance_of(from_token_id);
        let (expected_bal_from) = SafeUint256.sub_le(old_bal_from, value);
        assert_that.ERC3525_balance_of_is(from_token_id, expected_bal_from);

        assert_that.ERC3525_balance_of_is(new_token_id, value);

        assert_that.owner_is(from_token_id, old_owner);

        assert_that.ERC721_balance_of_is(old_owner, old_bal721_from);

        let (expected_bal721_to) = SafeUint256.add(old_bal721_to, Uint256(1, 0));
        assert_that.ERC721_balance_of_is(to, expected_bal721_to);

        assert_that.slot_of_is(from_token_id, old_slot);
        assert_that.slot_of_is(new_token_id, old_slot);

        return ();
    }

    func transfers_to_owner{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, caller: felt
    }(from_token_id: Uint256, to: felt, value: Uint256) {
        alloc_locals;

        let (local old_owner) = ERC721.owner_of(from_token_id);
        assert to = old_owner;

        let (local old_bal721) = ERC721.balance_of(old_owner);
        let (local old_bal_from) = ERC3525.balance_of(from_token_id);
        let (local old_slot) = ERC3525.slot_of(from_token_id);

        %{
            stop_prank = start_prank(ids.caller)
            mock_call(ids.to, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
            mock_call(ids.to, "supportsInterface", [ids.TRUE])
            expect_events({"name": "TransferValue"})
        %}
        let (new_token_id) = ERC3525.transfer_from(from_token_id, Uint256(0, 0), to, value);
        %{ stop_prank() %}

        let (expected_bal_from) = SafeUint256.sub_le(old_bal_from, value);
        assert_that.ERC3525_balance_of_is(from_token_id, expected_bal_from);

        assert_that.ERC3525_balance_of_is(new_token_id, value);

        assert_that.owner_is(from_token_id, old_owner);
        assert_that.owner_is(new_token_id, old_owner);

        let (expected_bal721) = SafeUint256.add(old_bal721, Uint256(1, 0));
        assert_that.ERC721_balance_of_is(to, expected_bal721);

        assert_that.slot_of_is(from_token_id, old_slot);
        assert_that.slot_of_is(new_token_id, old_slot);

        return ();
    }

    // Transfer_to_token
    func transfers_token{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, caller: felt
    }(from_token_id: Uint256, to_token_id: Uint256, value: Uint256) {
        alloc_locals;

        let (local old_from_owner) = ERC721.owner_of(from_token_id);
        let (local old_to_owner) = ERC721.owner_of(to_token_id);
        let (local old_bal721_from) = ERC721.balance_of(old_from_owner);
        let (local old_bal721_to) = ERC721.balance_of(old_to_owner);
        let (local old_bal_from) = ERC3525.balance_of(from_token_id);
        let (local old_bal_to) = ERC3525.balance_of(to_token_id);
        let (local old_from_slot) = ERC3525.slot_of(from_token_id);
        let (local old_to_slot) = ERC3525.slot_of(to_token_id);

        %{
            stop_prank = start_prank(ids.caller) 
            mock_call(ids.old_to_owner, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
            mock_call(ids.old_to_owner, "supportsInterface", [ids.TRUE])
            expect_events({"name": "TransferValue"})
        %}
        let (_) = ERC3525.transfer_from(from_token_id, to_token_id, 0, value);
        %{ stop_prank() %}

        let (expected_bal_from) = SafeUint256.sub_le(old_bal_from, value);
        assert_that.ERC3525_balance_of_is(from_token_id, expected_bal_from);

        let (expected_bal_to) = SafeUint256.add(old_bal_to, value);
        assert_that.ERC3525_balance_of_is(to_token_id, expected_bal_to);

        assert_that.owner_is(from_token_id, old_from_owner);
        assert_that.owner_is(to_token_id, old_to_owner);

        assert_that.ERC721_balance_of_is(old_from_owner, old_bal721_from);
        assert_that.ERC721_balance_of_is(old_to_owner, old_bal721_to);

        assert_that.slot_of_is(from_token_id, old_from_slot);
        assert_that.slot_of_is(to_token_id, old_to_slot);

        return ();
    }

    func transfers_token_same_id{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, caller: felt
    }(from_token_id: Uint256, to_token_id: Uint256, value: Uint256) {
        alloc_locals;

        let (is_eq) = uint256_eq(to_token_id, from_token_id);
        assert 1 = is_eq;

        let (local old_owner) = ERC721.owner_of(from_token_id);
        let (local old_bal721) = ERC721.balance_of(old_owner);
        let (local old_bal) = ERC3525.balance_of(from_token_id);
        let (local old_slot) = ERC3525.slot_of(from_token_id);
        %{
            stop_prank = start_prank(ids.caller) 
            mock_call(ids.old_owner, "onERC3525Received", [ids.IERC3525_RECEIVER_ID])
            mock_call(ids.old_owner, "supportsInterface", [ids.TRUE])
            expect_events({"name": "TransferValue"})
        %}
        let (_) = ERC3525.transfer_from(from_token_id, to_token_id, 0, value);
        %{ stop_prank() %}

        let (expected_bal) = ERC3525.balance_of(from_token_id);
        assert_that.ERC3525_balance_of_is(from_token_id, expected_bal);

        assert_that.owner_is(from_token_id, old_owner);
        assert_that.ERC721_balance_of_is(old_owner, old_bal721);
        assert_that.slot_of_is(from_token_id, old_slot);

        return ();
    }

    func approves{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, caller: felt}(
        token: felt, operator: felt, allowance: felt
    ) {
        alloc_locals;

        let infinity = Uint256(ALL_ONES, ALL_ONES);
        let token_id = Uint256(token, 0);

        if (allowance == -1) {
            %{
                stop_prank = start_prank(ids.caller)
                expect_events({"name": "ApprovalValue"})
            %}
            ERC3525.approve(token_id, operator, infinity);
            %{ stop_prank() %}
            assert_that.allowance_is(token_id, operator, infinity);
        } else {
            %{
                stop_prank = start_prank(ids.caller)
                expect_events({"name": "ApprovalValue"})
            %}
            ERC3525.approve(token_id, operator, Uint256(allowance, 0));
            %{ stop_prank() %}
            assert_that.allowance_is(token_id, operator, Uint256(allowance, 0));
        }

        return ();
    }
}
