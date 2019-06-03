package volkova.restful.digest.repository

import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.data.repository.Repository as MyRepository
import org.springframework.stereotype.Repository
import volkova.restful.digest.entity.Journal

@Repository
interface JournalsRepository : MyRepository<Journal, Int> {

    @Query(value = """select (journal_record(
                          cast_int(:id_journal),
                          cast_text(:title)
                      )).*""",
            nativeQuery = true)
    fun findSome(
            @Param("id_journal") idJournal: Int? = null,
            @Param("title") title: String? = null
    ): MutableList<Journal>

    @Query(value = """select (journal_record(all_record => true)).*""",
            nativeQuery = true)
    fun findAll(): MutableList<Journal>

    @Query(value = """select (journal_insert(
                          cast_text(:#{#journal.title})
                      )).*""",
            nativeQuery = true)
    fun add(@Param("journal") newJournal: Journal): Journal

    @Query(value = """select (journal_update(
                          cast_text(:#{#journal.title}),
                          cast_int(:#{#journal.idJournal})
                      )).*""",
            nativeQuery = true)
    fun set(@Param("journal") newJournal: Journal): Journal

    @Query(value = """select (journal_delete(cast_int(:id_journal))).*""",
            nativeQuery = true)
    fun remove(@Param("id_journal") idJournal: Int): Journal

}